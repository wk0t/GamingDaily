package com.wk0t.gamingdaily;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.DownloadManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Base64;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MainActivity extends Activity {
    private WebView web;
    private final ExecutorService pool = Executors.newFixedThreadPool(6);
    private TextToSpeech tts;
    private boolean ttsReady = false;
    private String pendingSpeak = null;
    private String pendingLang = "en";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setLoadsImagesAutomatically(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        web.addJavascriptInterface(new Bridge(), "AndroidBridge");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");

        // Text-to-speech (English)
        try {
            tts = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
                @Override
                public void onInit(int status) {
                    if (status == TextToSpeech.SUCCESS) {
                        try { tts.setLanguage(Locale.ENGLISH); } catch (Exception e) {}
                        try {
                            tts.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                                @Override public void onStart(String id) {}
                                @Override public void onDone(String id) {
                                    runOnUiThread(new Runnable() {
                                        @Override public void run() {
                                            web.evaluateJavascript("window.onSpeakDone&&onSpeakDone()", null);
                                        }
                                    });
                                }
                                @Override public void onError(String id) {}
                            });
                        } catch (Exception e) {}
                        ttsReady = true;
                        if (pendingSpeak != null) { doSpeak(pendingSpeak, pendingLang); pendingSpeak = null; }
                    }
                }
            });
        } catch (Exception e) {}

        // Notification permission (Android 13+) + daily reminder scheduling
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 1);
            }
        } catch (Exception e) {}
        try { NotifReceiver.scheduleDaily(this); } catch (Exception e) {}
    }

    private void doSpeak(String text, String lang) {
        if (tts == null || text == null) return;
        try {
            tts.setLanguage("fr".equals(lang) ? Locale.FRENCH : Locale.ENGLISH);
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "gmd");
        } catch (Exception e) {}
    }

    @Override
    protected void onDestroy() {
        try { if (tts != null) { tts.stop(); tts.shutdown(); } } catch (Exception e) {}
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.appBack ? appBack() : 'exit'", new android.webkit.ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                if (value == null || value.contains("exit")) {
                    finish();
                }
            }
        });
    }

    class Bridge {
        @JavascriptInterface
        public void fetchUrl(final String url, final int id) {
            pool.execute(new Runnable() {
                @Override
                public void run() {
                    String body = "";
                    try {
                        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
                        c.setConnectTimeout(12000);
                        c.setReadTimeout(12000);
                        c.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36");
                        c.setInstanceFollowRedirects(true);
                        InputStream in = c.getInputStream();
                        ByteArrayOutputStream bos = new ByteArrayOutputStream();
                        byte[] buf = new byte[8192];
                        int n;
                        while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
                        in.close();
                        byte[] bytes = bos.toByteArray();
                        String charset = null;
                        String ct = c.getContentType();
                        if (ct != null) {
                            Matcher m = Pattern.compile("(?i)charset=([\\w\\-]+)").matcher(ct);
                            if (m.find()) charset = m.group(1);
                        }
                        if (charset == null) {
                            String head = new String(bytes, 0, Math.min(bytes.length, 3000), "US-ASCII");
                            Matcher m = Pattern.compile("(?i)(?:encoding|charset)\\s*=\\s*[\"']?([\\w\\-]+)").matcher(head);
                            if (m.find()) charset = m.group(1);
                        }
                        if (charset == null) charset = "UTF-8";
                        body = new String(bytes, charset);
                    } catch (Exception e) {
                        body = "";
                    }
                    String b64;
                    try {
                        b64 = Base64.encodeToString(body.getBytes("UTF-8"), Base64.NO_WRAP);
                    } catch (Exception e) {
                        b64 = "";
                    }
                    final String payload = b64;
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            web.evaluateJavascript("onFetchDone(" + id + ",'" + payload + "')", null);
                        }
                    });
                }
            });
        }

        @JavascriptInterface
        public void speak(final String text, final String lang) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (ttsReady) doSpeak(text, lang); else { pendingSpeak = text; pendingLang = lang; }
                }
            });
        }

        // Stores the UI language so notifications follow it (set from the web UI language picker)
        @JavascriptInterface
        public void setLang(String lang) {
            try {
                getSharedPreferences("app", MODE_PRIVATE).edit().putString("lang", "fr".equals(lang) ? "fr" : "en").apply();
            } catch (Exception e) {}
        }

        @JavascriptInterface
        public void stopSpeak() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try { if (tts != null) tts.stop(); } catch (Exception e) {}
                    pendingSpeak = null;
                }
            });
        }

        @JavascriptInterface
        public void share(final String text) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        Intent i = new Intent(Intent.ACTION_SEND);
                        i.setType("text/plain");
                        i.putExtra(Intent.EXTRA_TEXT, text);
                        Intent chooser = Intent.createChooser(i, "Share article");
                        chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(chooser);
                    } catch (Exception e) {}
                }
            });
        }

        @JavascriptInterface
        public void saveCache(String data) {
            try {
                FileOutputStream f = openFileOutput("cache.json", MODE_PRIVATE);
                f.write(data.getBytes("UTF-8"));
                f.close();
            } catch (Exception e) { }
        }

        @JavascriptInterface
        public String loadCache() {
            try {
                FileInputStream f = openFileInput("cache.json");
                ByteArrayOutputStream b = new ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n;
                while ((n = f.read(buf)) > 0) b.write(buf, 0, n);
                f.close();
                return b.toString("UTF-8");
            } catch (Exception e) {
                return "";
            }
        }

        // Installed version (versionName from the manifest): compared against the latest published tag.
        @JavascriptInterface
        public String appVersion() {
            try {
                return getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
            } catch (Exception e) {
                return "";
            }
        }

        // Opens a URL in the browser (fallback for the update or the release page).
        @JavascriptInterface
        public void openUrl(final String url) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(i);
                    } catch (Exception e) {}
                }
            });
        }

        // Downloads the new version (APK) from GitHub through the system download
        // manager, then launches the installer AS SOON AS the download completes —
        // without relying on a notification tap (which can be hidden). On failure,
        // the URL is simply opened in the browser.
        @JavascriptInterface
        public void installUpdate(final String url) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    // Defense in depth: only install APKs served over HTTPS by GitHub.
                    if (url == null || !url.startsWith("https://")) return;
                    Uri src = Uri.parse(url);
                    String host = src.getHost();
                    boolean trusted = host != null && (host.equals("github.com")
                            || host.endsWith(".github.com") || host.endsWith(".githubusercontent.com"));
                    if (!trusted) return;
                    try {
                        final DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                        DownloadManager.Request req = new DownloadManager.Request(src);
                        req.setTitle("Gaming Daily — update");
                        req.setDescription("Downloading the new version...");
                        req.setMimeType("application/vnd.android.package-archive");
                        req.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                        // App-private folder: no storage permission needed on any Android version.
                        req.setDestinationInExternalFilesDir(MainActivity.this, Environment.DIRECTORY_DOWNLOADS,
                                "GamingDaily-update-" + System.currentTimeMillis() + ".apk");
                        final long id = dm.enqueue(req);

                        // When the download finishes we launch the installer ourselves: the
                        // "allow this source" prompt then targets Gaming Daily, and installing
                        // works even when notifications are disabled.
                        final BroadcastReceiver[] holder = new BroadcastReceiver[1];
                        holder[0] = new BroadcastReceiver() {
                            @Override
                            public void onReceive(Context ctx, Intent intent) {
                                long done = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1);
                                if (done != id) return;
                                try {
                                    Uri apk = dm.getUriForDownloadedFile(id);
                                    if (apk != null) {
                                        Intent install = new Intent(Intent.ACTION_VIEW);
                                        install.setDataAndType(apk, "application/vnd.android.package-archive");
                                        install.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
                                        startActivity(install);
                                    }
                                } catch (Exception e) {}
                                try { unregisterReceiver(holder[0]); } catch (Exception e) {}
                            }
                        };
                        IntentFilter filter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
                        if (Build.VERSION.SDK_INT >= 33) {
                            registerReceiver(holder[0], filter, Context.RECEIVER_EXPORTED);
                        } else {
                            registerReceiver(holder[0], filter);
                        }
                    } catch (Exception e) {
                        try {
                            Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            startActivity(i);
                        } catch (Exception e2) {}
                    }
                }
            });
        }
    }
}
