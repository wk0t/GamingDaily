# =====================================================================
#  Gaming Daily  —  Ton magazine quotidien 100 % jeu vidéo
#  (actu, consoles, PC, modding/homebrew, rétro, esport)
#  Récupère les news directement (sans proxy), extrait le contenu
#  complet des articles (lecture intégrée, sans pub) et génère le
#  magazine HTML dans le dossier temporaire.
#  IMPORTANT : ce fichier doit rester encodé en UTF-8 AVEC BOM
#  (sinon Windows PowerShell 5.1 casse les accents).
# =====================================================================
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 } catch {}
[System.Net.ServicePointManager]::DefaultConnectionLimit = 16

$outFile = Join-Path $env:TEMP "GamingDaily_magazine.html"

# Dépôt GitHub utilisé pour la vérification des mises à jour
$githubRepo = 'wk0t/GamingDaily'

# ---- Sources (flux RSS) — lang='en' => l'article sera traduit en français ----
$feeds = @(
  # --- Actu jeu vidéo (FR) ---
  @{url="https://www.jeuxvideo.com/rss/rss-news.xml";                              name="jeuxvideo.com";    cat="actu"; lang="fr"},
  @{url="https://gamekult.com/feed.xml";                                           name="Gamekult";         cat="actu"; lang="fr"},
  @{url="https://www.actugaming.net/feed/";                                        name="ActuGaming";       cat="actu"; lang="fr"},
  @{url="https://www.gameblog.fr/rss";                                             name="Gameblog";         cat="actu"; lang="fr"},
  @{url="https://www.jvfrance.com/feed/";                                          name="JVFrance";         cat="actu"; lang="fr"},
  @{url="https://www.indiemag.fr/rss.xml";                                         name="IndieMag";         cat="actu"; lang="fr"},
  # --- Consoles (FR) ---
  @{url="https://blog.fr.playstation.com/feed/";                                   name="PlayStation Blog"; cat="console"; lang="fr"},
  @{url="https://news.xbox.com/fr-fr/feed/";                                       name="Xbox Wire";        cat="console"; lang="fr"},
  @{url="https://www.nintendo-town.fr/feed/";                                      name="Nintendo-Town";    cat="console"; lang="fr"},
  @{url="https://www.xboxsquad.fr/feed/";                                          name="XboxSquad";        cat="console"; lang="fr"},
  @{url="https://gamergen.com/rss/";                                               name="Gamergen";         cat="console"; lang="fr"},
  @{url="https://www.frandroid.com/produits-android/console/feed";                 name="Frandroid Gaming"; cat="console"; lang="fr"},
  # --- PC (FR) ---
  @{url="https://nofrag.com/feed/";                                                name="NoFrag";           cat="pc";   lang="fr"},
  # --- Actu jeu vidéo (EN, traduit) ---
  @{url="https://feeds.feedburner.com/ign/games-all";                              name="IGN";              cat="actu"; lang="en"},
  @{url="https://www.gamespot.com/feeds/game-news/";                               name="GameSpot";         cat="actu"; lang="en"},
  @{url="https://www.eurogamer.net/feed";                                          name="Eurogamer";        cat="actu"; lang="en"},
  @{url="https://kotaku.com/rss";                                                  name="Kotaku";           cat="actu"; lang="en"},
  @{url="https://www.polygon.com/rss/index.xml";                                   name="Polygon";          cat="actu"; lang="en"},
  @{url="https://www.videogameschronicle.com/feed/";                               name="VGC";              cat="actu"; lang="en"},
  @{url="https://www.destructoid.com/feed/";                                       name="Destructoid";      cat="actu"; lang="en"},
  @{url="https://insider-gaming.com/feed/";                                        name="Insider Gaming";   cat="actu"; lang="en"},
  # --- PC (EN, traduit) ---
  @{url="https://www.pcgamer.com/rss/";                                            name="PC Gamer";         cat="pc";   lang="en"},
  @{url="https://www.rockpapershotgun.com/feed";                                   name="Rock Paper Shotgun";cat="pc";  lang="en"},
  # --- Consoles (EN, traduit) ---
  @{url="https://www.pushsquare.com/feeds/latest";                                 name="Push Square";      cat="console"; lang="en"},
  @{url="https://www.nintendolife.com/feeds/latest";                               name="Nintendo Life";    cat="console"; lang="en"},
  @{url="https://www.purexbox.com/feeds/latest";                                   name="Pure Xbox";        cat="console"; lang="en"},
  # --- Modding / homebrew / rétro (EN, traduit) ---
  @{url="https://wololo.net/feed/";                                                name="Wololo";           cat="modding"; lang="en"},
  @{url="https://www.timeextension.com/feeds/latest";                              name="Time Extension";   cat="modding"; lang="en"},
  @{url="https://www.retrorgb.com/feed";                                           name="RetroRGB";         cat="modding"; lang="en"}
)

# ---- Conteneur du corps d'article, par site (calibré par analyse des sources) ----
$siteContainer = @{
  'jeuxvideo.com'            = 'txt-article'
  'actugaming.net'           = 'entry-content'
  'jvfrance.com'             = 'entry-content'
  'nofrag.com'               = 'entry-content'
  'nintendo-town.fr'         = 'entry-content'
  'xboxsquad.fr'             = 'entry-content'
  'wololo.net'               = 'entry-content'
  'retrorgb.com'             = 'entry-content'
  'insider-gaming.com'       = 'entry-content'
  'videogameschronicle.com'  = 'entry-content'
  'destructoid.com'          = 'entry-content'
  'eurogamer.net'            = 'article_body'
  'rockpapershotgun.com'     = 'article_body'
  'gamespot.com'             = 'content-body'
  'pcgamer.com'              = 'article-body'
  'ign.com'                  = 'article-content'
  'frandroid.com'            = 'article-body'
  'gameblog.fr'              = 'article-content'
}

# ---- Mots-clés pour affiner la catégorie (SANS accents : comparés après repli) ----
$kw = @{
  modding = @('homebrew','jailbreak','custom firmware',' cfw ','hack de la','hackee','moddee','emulateur','emulation','emulator','romhack','rom hack','flashcart','linker','atmosphere','luma3ds','retroarch','mister fpga','everdrive','fan game','fan-game','patch fr','traduction de fan','decompilation','retro-ingenierie','reverse engineering','retrogaming','retro gaming','console retro','preservation des jeux','datamine','dataminee','moddeur','modders','mods ',' mod ','modding','overclocking de console','portage non officiel','unofficial port')
  esport  = @('esport','e-sport','tournoi','competitif','competition','lec ','lfl ','worlds','major de','dreamhack',' evo ','cash prize','equipe professionnelle','joueur professionnel','pro player','championnat du monde','coupe du monde de','qualifier','bootcamp','karmine','vitality','gentle mates','t1 ','g2 esports','faker')
  console = @('playstation','ps5','ps6','ps4','psn ','ps plus','dualsense','xbox','game pass','series x','series s','nintendo','switch','joy-con','wii ','3ds','game boy','gamecube','mario','zelda','pokemon','kirby','metroid','steam deck','rog ally','portable de valve','console portable','manette','dock ','firmware de la console','mise a jour systeme','retrocompatibilite','exclusivite console','showcase playstation','state of play','nintendo direct')
  pc      = @('steam ','sur steam','epic games store','gog ','carte graphique',' gpu','nvidia','geforce','rtx ','radeon',' amd ','ryzen','intel','dlss','fsr ','ray tracing','pc gamer','sur pc','version pc','drivers','pilotes','directx','vulkan','moteur unreal','unreal engine','unity ','configuration requise','config requise','benchmark','framerate','optimisation pc','micro-transactions sur pc','overclock','windows 11','w11 ','ssd ')
}

# ---- Enlève les accents (matching robuste, insensible aux accents/encodage) ----
function Remove-Diacritics([string]$s) {
  if ([string]::IsNullOrEmpty($s)) { return "" }
  $n = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$sb.Append($c)
    }
  }
  return $sb.ToString().Normalize([Text.NormalizationForm]::FormC).ToLower()
}

# ---- Filtre anti-pub / hors-sujet (+ guides/soluces : on garde la vraie actu) ----
$blockLink = @('/bons-plans/','/bon-plan','/bons-plans','/deals/','/promo','/coupon','/soldes','/wikis-soluces','/soluce','/astuces/','/guides/','/tips/','/guide/')
$blockTitle = @(
  'bon plan','bons plans','soldes','promo','reduction','remise','prix casse',
  'moins cher','pas cher','meilleur prix','a prix','french days','black friday','prime day',
  'cyber monday','ventes flash','vente flash','code promo','cashback','destockage',
  'sans payer','en stock','trouver du stock','ou acheter','bon d achat',
  '% de reduction','-20%','-30%','-40%','-50%','-60%','-70%',
  'horoscope','guide d achat','meilleures offres','offre du jour','le deal ','les deals',
  'soluce','notre guide complet','ou trouver','comment obtenir','comment debloquer',
  'comment avoir','comment battre','tier list','codes actifs','tous les codes',
  'emplacement de','emplacements de','tous les secrets','toutes les recompenses','wiki '
)
function Is-Junk([string]$title, [string]$link) {
  $t = Remove-Diacritics $title
  $l = $link.ToLower()
  foreach ($w in $blockLink)  { if ($l.Contains($w)) { return $true } }
  foreach ($w in $blockTitle) { if ($t.Contains($w)) { return $true } }
  return $false
}

# ---- Filtre POSITIF : uniquement du contenu lié au jeu vidéo ----
$topic = @(
  'jeu ','jeux','game','gaming','gamer','joueur','player','video game','videogame',
  'console','manette','gamepad','playstation','ps5','ps6','ps4','psn','ps plus','dualsense',
  'xbox','game pass','series x','series s','nintendo','switch','joy-con','wii','3ds','game boy',
  'gamecube','steam','valve','epic games','gog','steam deck','rog ally','portable',
  'studio','editeur','developpeur','developer','ubisoft','electronic arts',' ea ','activision',
  'blizzard','rockstar','bethesda','capcom','sega','square enix','bandai','konami','fromsoftware',
  'naughty dog','insomniac','cd projekt','larian','riot','bungie','remedy','kojima','miyamoto',
  'fortnite','minecraft','roblox','gta','zelda','mario','pokemon','kirby','metroid','call of duty',
  'battlefield','fifa','ea sports','valorant','league of legends','overwatch','apex','diablo',
  'final fantasy','resident evil','assassin','elden ring','dark souls','baldur','starfield',
  'cyberpunk','witcher','halo','god of war','last of us','horizon','spider-man','silksong',
  'hollow knight','stardew','terraria','doom','half-life','portal','counter-strike','cs2','dota',
  'monster hunter','dragon ball','naruto','street fighter','tekken','mortal kombat','smash bros',
  'animal crossing','splatoon','fire emblem','persona','yakuza','metal gear','sonic','crash',
  'gameplay','trailer','bande-annonce','dlc','extension','season pass','battle pass','early access',
  'acces anticipe','beta','demo','remake','remaster','portage','exclusivite','sortie du jeu',
  'date de sortie','test du jeu','review','preview','patch','mise a jour','maj ','update',
  'esport','e-sport','tournoi','twitch','streamer','speedrun','speedrunner',
  'emulateur','emulation','homebrew','jailbreak','custom firmware','cfw','romhack','rom ',
  'flashcart','retrogaming','retro','mod ','mods','modding','moddeur','fan game','datamine',
  'free-to-play','f2p','pay-to-win','microtransaction','lootbox','loot box','gacha','skin',
  'cross-play','crossplay','multijoueur','multiplayer','coop','pvp','pve','mmo','moba','fps',
  'rpg','jrpg','metroidvania','roguelike','roguelite','soulslike','battle royale','open world',
  'monde ouvert','vr ','realite virtuelle','psvr','cloud gaming','geforce now','luna',
  'carte graphique','gpu','nvidia','geforce','rtx','radeon','ryzen','dlss','fsr','ray tracing',
  'directx','unreal engine','unity','godot','moteur de jeu','framerate',' fps','60 fps','120 fps'
)
function Is-Relevant([string]$title, [string]$excerpt) {
  $t = ' ' + (Remove-Diacritics ($title + ' ' + $excerpt)) + ' '
  foreach ($w in $topic) { if ($t.Contains($w)) { return $true } }
  return $false
}

# ---- Phrases parasites dans le corps des articles (repliées sans accent) ----
# Phrases assez spécifiques pour ne jamais couper un vrai paragraphe.
$junkPhrases = @(
  # FR — renvois / newsletter / partage / pub
  'lire aussi','a lire egalement','a lire :','a lire aussi','sur le meme sujet','sur le meme theme',
  'a decouvrir aussi','voir aussi :','dans la meme rubrique','notre dossier complet','notre comparatif',
  'abonnez-vous','abonne-toi','inscrivez-vous a','notre newsletter','la newsletter','recevez chaque',
  'recevez toute l actualite','recevez le meilleur','suivez-nous sur','suivez nous sur','rejoignez-nous',
  'rejoignez notre','partagez cet article','partager sur','partager cet article','cliquez ici pour',
  'laisser un commentaire','votre adresse e-mail','votre adresse email','pour aller plus loin',
  'cet article vous a plu','soutenez-nous','faire un don','sur patreon','sur tipeee','en partenariat avec',
  'article sponsorise','ceci est une publicite','contenu sponsorise','politique de confidentialite',
  'gerer mes cookies','accepter les cookies','tous droits reserves','credit photo','credits photo',
  'telechargez l application','notre application','meilleurs vpn','notre guide d achat','code promo',
  # EN — renvois / newsletter / partage / pub
  'read more:','also read:','you might also','you may also','related articles','related stories',
  'related reading','recommended for you','sign up for','subscribe to','our newsletter','follow us on',
  'share this article','leave a comment','all rights reserved','found this article interesting',
  'advertisement','sponsored content','sponsored by','in partnership with','this article originally appeared',
  'trending now','most popular','more from','join the conversation','click here to','continue reading'
)
function Test-JunkParagraph([string]$txt) {
  $t = Remove-Diacritics $txt
  foreach ($w in $junkPhrases) { if ($t.Contains($w)) { return $true } }
  return $false
}

function Clean-Text([string]$html) {
  if ([string]::IsNullOrEmpty($html)) { return "" }
  $t = $html
  $t = [regex]::Replace($t, '(?s)<!\[CDATA\[(.*?)\]\]>', '$1')
  $t = [regex]::Replace($t, '(?s)<[^>]+>', ' ')
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}

function Get-Tag([string]$xml, [string]$tag) {
  $m = [regex]::Match($xml, "(?s)<$tag(?:\s[^>]*)?>(.*?)</$tag>")
  if ($m.Success) { return $m.Groups[1].Value }
  return ""
}

function Resolve-Url([string]$u, [string]$pageUrl) {
  if ([string]::IsNullOrWhiteSpace($u)) { return "" }
  if ($u -match '^https?://') { return $u }
  if ($u.StartsWith('//')) { return 'https:' + $u }
  if ($u.StartsWith('/')) {
    $m = [regex]::Match($pageUrl, '^(https?://[^/]+)')
    if ($m.Success) { return $m.Groups[1].Value + $u }
  }
  return ""
}

function Get-ImgSrc([string]$imgTag, [string]$pageUrl) {
  # vignettes d'articles liés / miniatures WordPress : à ignorer
  if ($imgTag -match '(?i)attachment-thumbnail|attachment-medium|wp-post-image') { return "" }
  foreach ($attr in @('data-lazy-src','data-src','data-original','src')) {
    $m = [regex]::Match($imgTag, $attr + '\s*=\s*["'']([^"'']+)["'']', 'IgnoreCase')
    if (-not $m.Success) { continue }
    $u = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value.Trim())
    if ($u.StartsWith('data:')) { continue }
    $u = Resolve-Url $u $pageUrl
    if (-not $u) { continue }
    $low = $u.ToLower()
    $bad = $false
    foreach ($j in @('logo','icon','avatar','badge','pixel','1x1','150x150','emoji','smiley','gravatar','feedburner','doubleclick','/ads/','/ad/','adservice','adserver','taboola','outbrain','optidigital','criteo','banner','sponsor','captcha','.svg','tracking','/track','beacon','bleepstatic.com/c/','/promoted/','/sponsored/')) {
      if ($low.Contains($j)) { $bad = $true; break }
    }
    if ($bad) { continue }
    return $u
  }
  return ""
}

function Get-Image([string]$block) {
  foreach ($rx in @(
      '<media:content[^>]*url="([^"]+\.(?:jpg|jpeg|png|webp|gif)[^"]*)"',
      '<media:content[^>]*medium="image"[^>]*url="([^"]+)"',
      '<media:content[^>]*url="([^"]+)"[^>]*medium="image"',
      '<media:thumbnail[^>]*url="([^"]+)"',
      '<enclosure[^>]*url="([^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"',
      '<img[^>]*src="([^"]+)"',
      '<img[^>]*src=''([^'']+)''' )) {
    $m = [regex]::Match($block, $rx, 'IgnoreCase')
    if ($m.Success) {
      $u = $m.Groups[1].Value.Trim()
      if ($u.StartsWith('//')) { $u = 'https:' + $u }
      if ($u -match '^https?://') { return $u }
    }
  }
  return ""
}

# ---- Image de couverture depuis les métadonnées de la page (og:image / twitter:image) ----
function Get-OgImage([string]$page) {
  if ([string]::IsNullOrWhiteSpace($page)) { return "" }
  foreach ($rx in @(
      '<meta[^>]+property\s*=\s*["'']og:image(?::url)?["''][^>]*content\s*=\s*["'']([^"'']+)["'']',
      '<meta[^>]+content\s*=\s*["'']([^"'']+)["''][^>]*property\s*=\s*["'']og:image["'']',
      '<meta[^>]+name\s*=\s*["'']twitter:image["''][^>]*content\s*=\s*["'']([^"'']+)["'']')) {
    $m = [regex]::Match($page, $rx, 'IgnoreCase')
    if ($m.Success) {
      $u = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value.Trim())
      if ($u.StartsWith('//')) { $u = 'https:' + $u }
      if ($u -match '^https?://' -and $u -notmatch '\.svg') { return $u }
    }
  }
  return ""
}

function Get-Cat([string]$base, [string]$text) {
  $t = Remove-Diacritics $text
  foreach ($w in $kw.modding) { if ($t.Contains($w)) { return 'modding' } }
  foreach ($w in $kw.esport)  { if ($t.Contains($w)) { return 'esport' } }
  foreach ($w in $kw.console) { if ($t.Contains($w)) { return 'console' } }
  foreach ($w in $kw.pc)      { if ($t.Contains($w)) { return 'pc' } }
  return $base
}

# ---- Extraction des blocs (paragraphes, sous-titres, images) d'un HTML ----
function Extract-Blocks([string]$html, [string]$pageUrl) {
  $out = New-Object System.Collections.Generic.List[object]
  if ([string]::IsNullOrWhiteSpace($html)) { return @() }
  $h = $html
  $h = [regex]::Replace($h, '(?is)<!\[CDATA\[(.*?)\]\]>', '$1')
  # description encodée en entités HTML (&lt;p&gt;) -> décoder d'abord
  if ($h -notmatch '(?i)<p[\s>]' -and $h -match '(?i)&lt;p') { $h = [System.Net.WebUtility]::HtmlDecode($h) }
  $h = [regex]::Replace($h, '(?is)<script\b.*?</script>', ' ')
  $h = [regex]::Replace($h, '(?is)<style\b.*?</style>', ' ')
  $h = [regex]::Replace($h, '(?is)<!--.*?-->', ' ')
  $h = [regex]::Replace($h, '(?is)<(aside|nav|footer|form|figcaption|button|svg)\b[^>]*>.*?</\1>', ' ')
  # retire les blocs pub / newsletter / articles liés (par classe CSS connue)
  $h = [regex]::Replace($h, '(?is)<(div|section|ul)\b[^>]*\b(?:class|id)\s*=\s*["''][^"'']*(?:ad-|-ad\b|ads\b|advert|optidigital|od-wrapper|taboola|outbrain|mc4wp|newsletter|related-|-related|share|social|sponsor|promo|ars-interlude|most-read|most-popular|read-also|lire-aussi|partner|affiliate|abo-|paywall|comment)[^"'']*["''][^>]*>.*?</\1>', ' ')
  $nText = 0; $nImg = 0
  foreach ($m in [regex]::Matches($h, '(?is)<(p|h2|h3|li|blockquote)(?:\s[^>]*)?>(.*?)</\1>|<img\b[^>]*>')) {
    if ($m.Value -match '(?i)^<img') {
      if ($nImg -ge 8) { continue }
      $src = Get-ImgSrc $m.Value $pageUrl
      if ($src) {
        $dup = $false
        foreach ($b in $out) { if ($b.t -eq 'img' -and $b.v -eq $src) { $dup = $true; break } }
        if (-not $dup) { $out.Add([pscustomobject]@{ t='img'; v=$src }); $nImg++ }
      }
    } else {
      if ($nText -ge 40) { continue }
      $tag = $m.Groups[1].Value.ToLower()
      $raw = $m.Groups[2].Value
      $txt = Clean-Text $raw
      if ($tag -eq 'h2' -or $tag -eq 'h3') {
        if ($txt.Length -ge 8 -and $txt.Length -le 200 -and -not (Test-JunkParagraph $txt)) {
          $out.Add([pscustomobject]@{ t='h'; v=$txt }); $nText++
        }
      } else {
        # un paragraphe qui n'est presque qu'un lien = renvoi "Lire aussi" -> on saute
        $isLinkOnly = ($raw -match '(?i)<a\b') -and ($txt.Length -lt 130)
        if ($txt.Length -ge 60 -and -not $isLinkOnly -and -not (Test-JunkParagraph $txt)) {
          $out.Add([pscustomobject]@{ t='p'; v=$txt }); $nText++
        }
      }
    }
  }
  return $out.ToArray()
}

# ---- Isole la région principale d'une page article ----
function Get-MainRegion([string]$page, [string]$link) {
  if ([string]::IsNullOrWhiteSpace($page)) { return "" }
  $siteHost = ([regex]::Match($link, '^https?://([^/]+)')).Groups[1].Value.ToLower()
  $hint = $null
  foreach ($k in $siteContainer.Keys) { if ($siteHost.Contains($k.ToLower())) { $hint = $siteContainer[$k]; break } }
  $patterns = @()
  if ($hint -and $hint -ne 'article') { $patterns += $hint }
  if (-not $hint -or $hint -eq 'article') {
    $arts = [regex]::Matches($page, '(?is)<article\b[^>]*>(.*?)</article>')
    if ($arts.Count -gt 0) {
      $best = ''
      foreach ($a in $arts) { if ($a.Groups[1].Value.Length -gt $best.Length) { $best = $a.Groups[1].Value } }
      if ($best.Length -gt 1500) { return $best }
    }
  }
  $patterns += @('entry-content','article__content','article-content','article-body','articlebody','post-content','post_content','post-body','obj_text','c-article','content-article','article_content','td-post-content','single-content','story-body','article-text')
  foreach ($pat in $patterns) {
    $mm = [regex]::Match($page, '(?is)<(div|section)\b[^>]*class\s*=\s*["''][^"'']*' + [regex]::Escape($pat) + '[^"'']*["''][^>]*>')
    if ($mm.Success) {
      $start = $mm.Index
      $len = [Math]::Min(80000, $page.Length - $start)
      return $page.Substring($start, $len)
    }
  }
  return $page  # dernier recours : les filtres de paragraphes feront le tri
}

# ---- Téléchargeur partagé (détecte l'encodage : en-tête HTTP, prologue XML, meta) ----
$dlScript = {
  param($u)
  try {
    $req = [System.Net.HttpWebRequest]::Create($u)
    $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    $req.Accept = 'text/html,application/xhtml+xml,application/xml,text/xml,*/*'
    $req.Timeout = 12000
    $req.ReadWriteTimeout = 12000
    $req.AllowAutoRedirect = $true
    $resp = $req.GetResponse()
    $ms = New-Object System.IO.MemoryStream
    $resp.GetResponseStream().CopyTo($ms)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    $charset = ''
    if ($resp.ContentType -match 'charset=([\w\-]+)') { $charset = $Matches[1] }
    $resp.Close()
    if (-not $charset) {
      $head = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(4096, $bytes.Length))
      if ($head -match '(?i)(?:charset|encoding)\s*=\s*["'']?([\w\-]+)') { $charset = $Matches[1] }
    }
    $enc = [System.Text.Encoding]::UTF8
    if ($charset) { try { $enc = [System.Text.Encoding]::GetEncoding($charset) } catch {} }
    return $enc.GetString($bytes)
  } catch { return "" }
}
# télécharge une liste d'URLs en parallèle -> tableau aligné sur l'entrée
function Fetch-Many([string[]]$urls) {
  $pool = [runspacefactory]::CreateRunspacePool(1, 10)
  $pool.Open()
  $jobs = @()
  foreach ($u in $urls) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($dlScript).AddArgument($u)
    $jobs += @{ ps = $ps; handle = $ps.BeginInvoke() }
  }
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($j in $jobs) {
    $c = ""
    try { $c = ($j.ps.EndInvoke($j.handle) | Select-Object -First 1) } catch { $c = "" }
    $j.ps.Dispose()
    $out.Add([string]$c)
  }
  $pool.Close()
  return $out.ToArray()
}

# =====================================================================
#  PHASE 1 — Récupération des flux (en parallèle)
# =====================================================================
Write-Host "Récupération des dernières news..." -ForegroundColor Cyan
$items = New-Object System.Collections.Generic.List[object]
$seen  = New-Object System.Collections.Generic.HashSet[string]

$feedContents = Fetch-Many ($feeds | ForEach-Object { $_.url })

for ($fi = 0; $fi -lt $feeds.Count; $fi++) {
  $f = $feeds[$fi]
  $content = $feedContents[$fi]
  if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Host ("  - {0} : indisponible" -f $f.name) -ForegroundColor DarkYellow
    continue
  }

  $blocks = [regex]::Matches($content, '(?s)<item(?:\s[^>]*)?>.*?</item>')
  if ($blocks.Count -eq 0) { $blocks = [regex]::Matches($content, '(?s)<entry(?:\s[^>]*)?>.*?</entry>') }

  $n = 0
  foreach ($bm in $blocks) {
    $b = $bm.Value

    $title = Clean-Text (Get-Tag $b 'title')
    if ([string]::IsNullOrWhiteSpace($title)) { continue }

    $link = (Get-Tag $b 'link').Trim()
    if ([string]::IsNullOrWhiteSpace($link) -or $link -notmatch '^https?://') {
      $lm = [regex]::Match($b, '<link[^>]*href="([^"]+)"')
      if ($lm.Success) { $link = $lm.Groups[1].Value }
    }
    $link = ($link -replace '(?s)<!\[CDATA\[(.*?)\]\]>','$1').Trim()
    if ($link -notmatch '^https?://') { continue }

    # écarte pub / bons plans / streaming sport / hors-sujet
    if (Is-Junk $title $link) { continue }

    # dédoublonnage par titre
    $key = $title.ToLower()
    if (-not $seen.Add($key)) { continue }

    $rawDesc = Get-Tag $b 'description'
    if ([string]::IsNullOrWhiteSpace($rawDesc)) { $rawDesc = Get-Tag $b 'summary' }
    $rawFull = Get-Tag $b 'content:encoded'
    if ([string]::IsNullOrWhiteSpace($rawFull)) { $rawFull = Get-Tag $b 'content' }
    if ([string]::IsNullOrWhiteSpace($rawFull)) { $rawFull = $rawDesc }
    if ([string]::IsNullOrWhiteSpace($rawDesc)) { $rawDesc = $rawFull }

    $excerpt = Clean-Text $rawDesc
    $fullText = $excerpt
    if ($excerpt.Length -gt 180) { $excerpt = $excerpt.Substring(0,180) }

    # ne garder que les articles réellement liés à l'informatique
    if (-not (Is-Relevant $title $fullText)) { continue }

    $img = Get-Image $b
    if ([string]::IsNullOrWhiteSpace($img)) { $img = Get-Image $rawFull }

    $dateStr = (Get-Tag $b 'pubDate').Trim()
    if ([string]::IsNullOrWhiteSpace($dateStr)) { $dateStr = (Get-Tag $b 'published').Trim() }
    if ([string]::IsNullOrWhiteSpace($dateStr)) { $dateStr = (Get-Tag $b 'updated').Trim() }
    $iso = ""; $ticks = [long]0
    $dt = [datetime]::MinValue
    if ([datetime]::TryParse($dateStr, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) {
      $iso = $dt.ToUniversalTime().ToString("o")
      $ticks = $dt.ToUniversalTime().Ticks
    }

    $cat = Get-Cat $f.cat ($title + ' ' + $excerpt)

    $items.Add([pscustomobject]@{
      title      = $title
      link       = $link
      excerpt    = $excerpt
      img        = $img
      source     = $f.name
      cat        = $cat
      date       = $iso
      sort       = $ticks
      rawFull    = $rawFull
      body       = $null
      lang       = $f.lang
      translated = $false
    })
    $n++
    if ($n -ge 12) { break }
  }
  Write-Host ("  + {0} : {1} articles" -f $f.name, $n) -ForegroundColor Green
}

# tri par date décroissante, on garde les 60 plus récents
$top = @($items | Sort-Object -Property sort -Descending | Select-Object -First 60)

# =====================================================================
#  PHASE 2 — Contenu complet pour la lecture intégrée
# =====================================================================
Write-Host "Extraction du contenu des articles (lecture intégrée)..." -ForegroundColor Cyan

$needFetch = New-Object System.Collections.Generic.List[object]
foreach ($it in $top) {
  $blocks = @()
  if ($it.rawFull -and (Clean-Text $it.rawFull).Length -gt 600) {
    $blocks = @(Extract-Blocks $it.rawFull $it.link)
  }
  if ($blocks.Count -ge 3) { $it.body = $blocks }
  # on télécharge la page s'il manque le corps OU l'image de couverture
  if ($blocks.Count -lt 3 -or [string]::IsNullOrWhiteSpace($it.img)) { $needFetch.Add($it) }
}
Write-Host ("  {0} articles complets via le flux, {1} pages à télécharger..." -f ($top.Count - $needFetch.Count), $needFetch.Count)

if ($needFetch.Count -gt 0) {
  $pages = Fetch-Many ($needFetch | ForEach-Object { $_.link })
  $okPages = 0
  for ($pi = 0; $pi -lt $needFetch.Count; $pi++) {
    $it = $needFetch[$pi]
    $pageHtml = $pages[$pi]
    if ($pageHtml) {
      # image de couverture manquante -> og:image de la page
      if ([string]::IsNullOrWhiteSpace($it.img)) {
        $og = Get-OgImage $pageHtml
        if ($og) { $it.img = $og }
      }
      # corps manquant -> on l'extrait
      if (-not $it.body) {
        $region = Get-MainRegion $pageHtml $it.link
        $blocks = @(Extract-Blocks $region $it.link)
        if ($blocks.Count -ge 2) { $it.body = $blocks; $okPages++ }
      }
    }
  }
  Write-Host ("  {0}/{1} pages extraites avec succès" -f $okPages, $needFetch.Count) -ForegroundColor Green
}

# dernier repli image de couverture : 1re image du corps de l'article
foreach ($it in $top) {
  if ([string]::IsNullOrWhiteSpace($it.img) -and $it.body) {
    foreach ($bl in $it.body) { if ($bl.t -eq 'img' -and $bl.v) { $it.img = $bl.v; break } }
  }
}

# =====================================================================
#  PHASE 3 — Traduction automatique des articles en anglais
# =====================================================================
$toTranslate = @($top | Where-Object { $_.lang -eq 'en' })
if ($toTranslate.Count -gt 0) {
  Write-Host ("Traduction de {0} articles anglais vers le français..." -f $toTranslate.Count) -ForegroundColor Cyan
  $trScript = {
    param($texts)
    function Send-Batch($arr) {
      if ($arr.Count -eq 0) { return @() }
      $blob = ($arr -join "`n[[[0]]]`n")
      try {
        $u = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=fr&dt=t&q=" + [Uri]::EscapeDataString($blob)
        $req = [Net.HttpWebRequest]::Create($u)
        $req.UserAgent = 'Mozilla/5.0'; $req.Timeout = 15000
        $resp = $req.GetResponse()
        $sr = New-Object IO.StreamReader($resp.GetResponseStream(), [Text.Encoding]::UTF8)
        $raw = $sr.ReadToEnd(); $sr.Close(); $resp.Close()
        $j = $raw | ConvertFrom-Json
        $outstr = (-join ($j[0] | ForEach-Object { $_[0] }))
        $parts = $outstr -split '\[\[\[0\]\]\]'
        if ($parts.Count -eq $arr.Count) { return @($parts | ForEach-Object { $_.Trim() }) }
        return $arr           # secours : jamais de perte d'ordre
      } catch { return $arr }
    }
    $res = New-Object System.Collections.Generic.List[string]
    $chunk = New-Object System.Collections.Generic.List[string]
    $len = 0
    foreach ($t in $texts) {
      if ($len -gt 0 -and ($len + $t.Length) -gt 1500) {
        foreach ($x in (Send-Batch $chunk)) { [void]$res.Add($x) }
        $chunk.Clear(); $len = 0
      }
      [void]$chunk.Add([string]$t); $len += $t.Length + 12
    }
    if ($chunk.Count -gt 0) { foreach ($x in (Send-Batch $chunk)) { [void]$res.Add($x) } }
    return $res.ToArray()
  }
  $pool2 = [runspacefactory]::CreateRunspacePool(1, 6)
  $pool2.Open()
  $tjobs = @()
  foreach ($it in $toTranslate) {
    $texts = New-Object System.Collections.Generic.List[string]
    [void]$texts.Add([string]$it.title)
    [void]$texts.Add([string]$it.excerpt)
    $idx = New-Object System.Collections.Generic.List[int]
    if ($it.body) {
      for ($k = 0; $k -lt $it.body.Count; $k++) {
        if ($it.body[$k].t -ne 'img') { [void]$texts.Add([string]$it.body[$k].v); [void]$idx.Add($k) }
      }
    }
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool2
    [void]$ps.AddScript($trScript).AddArgument($texts.ToArray())
    $tjobs += @{ ps = $ps; handle = $ps.BeginInvoke(); item = $it; idx = $idx }
  }
  $okTr = 0
  foreach ($j in $tjobs) {
    $tr = @()
    try { $tr = @($j.ps.EndInvoke($j.handle)) } catch { $tr = @() }
    $j.ps.Dispose()
    if ($tr.Count -ge 2) {
      $j.item.title   = $tr[0]
      $j.item.excerpt = $tr[1]
      for ($m = 0; $m -lt $j.idx.Count -and (2 + $m) -lt $tr.Count; $m++) {
        $j.item.body[$j.idx[$m]].v = $tr[2 + $m]
      }
      $j.item.translated = $true
      $okTr++
    }
  }
  $pool2.Close()
  Write-Host ("  {0}/{1} articles traduits" -f $okTr, $toTranslate.Count) -ForegroundColor Green
}

# objets finaux exportés (sans rawFull/sort)
$export = @($top | ForEach-Object {
  [pscustomobject]@{
    title      = $_.title
    link       = $_.link
    excerpt    = $_.excerpt
    img        = $_.img
    source     = $_.source
    cat        = $_.cat
    date       = $_.date
    translated = [bool]$_.translated
    body       = if ($_.body) { @($_.body) } else { @() }
  }
})

$json = ConvertTo-Json -InputObject $export -Depth 6 -Compress
if ([string]::IsNullOrWhiteSpace($json) -or $export.Count -eq 0) { $json = "[]" }
$json = $json.Replace('</', '<\/')

# =====================================================================
#  Vérification d'une nouvelle version (GitHub Releases)
#  On compare la version locale au dernier tag publié ; si une version
#  plus récente existe, une bannière proposera la mise à jour.
# =====================================================================
# ATTENTION : le numéro de version vit à 3 endroits qu'il faut bumper ENSEMBLE
# à chaque release -> $appVersion (ici), APP_VERSION (android/assets/index.html)
# et versionName (android/AndroidManifest.xml).
$appVersion = '1.0.0'

# Comparaison de versions segment par segment (miroir de cmpVersion() en JS) :
# tolère les tags à 1 ou 5+ segments et ignore un éventuel suffixe (-beta, -rc...).
function Test-NewerVersion([string]$latest, [string]$current) {
  $a = ((($latest  -replace '^[vV]', '') -split '-')[0]) -split '\.'
  $b = ((($current -replace '^[vV]', '') -split '-')[0]) -split '\.'
  for ($i = 0; $i -lt [Math]::Max($a.Count, $b.Count); $i++) {
    $x = 0; $y = 0
    [void][int]::TryParse((($a[$i]) -replace '[^0-9]', ''), [ref]$x)
    [void][int]::TryParse((($b[$i]) -replace '[^0-9]', ''), [ref]$y)
    if ($x -gt $y) { return $true }
    if ($x -lt $y) { return $false }
  }
  return $false
}

$updateJson = 'null'
try {
  $relRaw = (Fetch-Many @("https://api.github.com/repos/$githubRepo/releases/latest"))[0]
  if ($relRaw) {
    $tag = [regex]::Match($relRaw, '"tag_name"\s*:\s*"([^"]+)"').Groups[1].Value
    # On cible spécifiquement l'URL de la release (elle contient /releases/), pas
    # celle de l'auteur ni d'un asset.
    $relUrl = [regex]::Match($relRaw, '"html_url"\s*:\s*"(https://github\.com/[^"]+/releases/[^"]+)"').Groups[1].Value
    if (-not $relUrl) { $relUrl = "https://github.com/$githubRepo/releases/latest" }
    if ($tag -and (Test-NewerVersion $tag $appVersion)) {
      $verLabel = $tag -replace '^[vV]', ''    # même libellé que côté Android
      $updateJson = ConvertTo-Json ([pscustomobject]@{ available = $true; version = $verLabel; url = $relUrl }) -Compress
    }
  }
} catch {}

$fr = [Globalization.CultureInfo]::GetCultureInfo('fr-FR')
$dateJour = (Get-Date).ToString("dddd d MMMM yyyy", $fr)
$heure    = (Get-Date).ToString("HH:mm")

# ---------------------------------------------------------------
#  Gabarit HTML
# ---------------------------------------------------------------
$template = @'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gaming Daily</title>
<style>
  :root{
    --bg:#0d0a16;--card:#1a1428;--card2:#211a33;--line:#2f2547;--txt:#ece7f5;--muted:#9b8fb5;
    --accent:#8b5cff;--accent2:#ff4d8d;--gold:#ffb020;--radius:18px;--shadow:0 10px 30px rgba(0,0,0,.35);--fs:1;
  }
  *{box-sizing:border-box}html,body{margin:0;padding:0}
  body{
    background:radial-gradient(1200px 600px at 80% -10%, rgba(139,92,255,.16), transparent 60%),
      radial-gradient(900px 500px at -10% 10%, rgba(255,77,141,.10), transparent 55%),var(--bg);
    color:var(--txt);font-family:'Segoe UI',system-ui,-apple-system,Roboto,Arial,sans-serif;line-height:1.5;min-height:100vh;
    font-size:calc(16px * var(--fs));
  }
  .wrap{max-width:1240px;margin:0 auto;padding:26px 22px 80px}
  header.top{display:flex;align-items:flex-start;justify-content:space-between;gap:20px;flex-wrap:wrap;padding-bottom:18px;margin-bottom:18px;border-bottom:1px solid var(--line)}
  .brand h1{margin:0;font-size:34px;letter-spacing:.5px;font-weight:800;background:linear-gradient(90deg,#fff,#c9b3ff 60%,var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent}
  .brand .kick{display:inline-flex;align-items:center;gap:8px;font-size:12px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--accent2);margin-bottom:6px}
  .brand .kick .dot{width:8px;height:8px;border-radius:50%;background:var(--accent2);box-shadow:0 0 12px var(--accent2)}
  .headright{display:flex;flex-direction:column;align-items:flex-end;gap:8px}
  .headright .date{font-size:15px;font-weight:600;text-transform:capitalize}
  .headright .sub{font-size:12.5px;color:var(--muted)}
  .hbtns{display:flex;gap:8px}
  .iconbtn{width:40px;height:40px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-size:17px;cursor:pointer}
  .iconbtn.on{border-color:var(--accent);color:#fff;background:var(--card2)}
  .searchbar{margin-bottom:16px}
  .searchbar input{width:100%;background:var(--card);border:1px solid var(--line);border-radius:12px;color:var(--txt);padding:11px 16px;font-size:15px;outline:none}
  .searchbar input:focus{border-color:var(--accent)}
  .tip{position:relative;overflow:hidden;background:linear-gradient(120deg,#251a42,#1c1530 60%);border:1px solid var(--line);border-radius:var(--radius);padding:20px 22px;margin-bottom:16px;box-shadow:var(--shadow)}
  .tip .lbl{font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--accent2);font-weight:800}
  .tip h2{margin:8px 0 5px;font-size:20px}.tip p{margin:0;color:#cbd5ea;max-width:900px}
  .digest{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:18px 22px;margin-bottom:16px}
  .digest .lbl{font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--gold);font-weight:800;margin-bottom:10px}
  .digest ol{margin:0;padding-left:22px}
  .digest li{margin:0 0 8px;font-size:15px;line-height:1.4;cursor:pointer}
  .digest li:last-child{margin-bottom:0}
  .digest li b{color:var(--txt);font-weight:600}.digest li span{color:var(--muted);font-size:12.5px}
  .digest li:hover b{color:var(--accent)}
  .topics{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px}
  .topics .tlab{font-size:12px;color:var(--muted);font-weight:700}
  .topic{display:inline-flex;align-items:center;gap:6px;background:rgba(255,176,32,.13);border:1px solid rgba(255,176,32,.35);color:var(--gold);padding:5px 11px;border-radius:999px;font-size:12.5px;font-weight:600}
  .topic b{cursor:pointer;opacity:.7}
  .topic-add{background:var(--card);border:1px dashed var(--line);color:var(--muted);padding:5px 12px;border-radius:999px;font-size:12.5px;cursor:pointer}
  .filters{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px;align-items:center}
  .chip{border:1px solid var(--line);background:var(--card);color:var(--muted);padding:8px 16px;border-radius:999px;cursor:pointer;font-size:13.5px;font-weight:600}
  .chip.active{background:var(--accent);border-color:var(--accent);color:#fff}
  .chip.fav.active{background:#ff4d6d;border-color:#ff4d6d}
  .count{color:var(--muted);font-size:13px;margin-bottom:14px}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px}
  .card{position:relative;background:var(--card);border:1px solid var(--line);border-radius:var(--radius);overflow:hidden;display:flex;flex-direction:column;text-decoration:none;color:inherit;box-shadow:var(--shadow);transition:.18s;cursor:pointer}
  .card:hover{transform:translateY(-4px);border-color:#33405e}
  .card.read{opacity:.5}
  .card.pin{border-color:rgba(255,176,32,.5)}
  .thumb{position:relative;aspect-ratio:16/9;background:#0e131f;overflow:hidden}
  .thumb img{width:100%;height:100%;object-fit:cover;display:block;transition:.4s}
  .card:hover .thumb img{transform:scale(1.05)}
  .thumb .noimg{width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:44px;opacity:.4}
  .badge{position:absolute;left:12px;top:12px;font-size:11px;font-weight:800;letter-spacing:.5px;text-transform:uppercase;padding:5px 10px;border-radius:8px;color:#fff;backdrop-filter:blur(4px)}
  .b-actu{background:rgba(139,92,255,.92)}.b-console{background:rgba(255,77,109,.92)}.b-pc{background:rgba(79,124,255,.92)}.b-modding{background:rgba(255,176,32,.94);color:#1a1400}.b-esport{background:rgba(18,214,165,.92);color:#00251c}
  .heart{position:absolute;right:10px;top:10px;width:36px;height:36px;border-radius:50%;border:none;background:rgba(11,14,20,.55);color:#fff;font-size:17px;cursor:pointer;backdrop-filter:blur(4px);z-index:2}
  .heart.on{color:#ff4d6d}
  .pinstar{position:absolute;right:10px;bottom:10px;font-size:16px;filter:drop-shadow(0 1px 2px #000)}
  .body{padding:16px 18px 18px;display:flex;flex-direction:column;gap:8px;flex:1}
  .src{display:flex;align-items:center;justify-content:space-between;font-size:12px;color:var(--muted);gap:6px}
  .src .name{font-weight:700;color:#aab6cf}
  .src .tr{margin-left:7px;font-weight:600;font-size:10.5px;color:var(--accent2);background:rgba(18,214,165,.12);border:1px solid rgba(18,214,165,.3);padding:1px 6px;border-radius:6px}
  .src .meta{white-space:nowrap}
  .card h3{margin:0;font-size:17px;line-height:1.35}
  .card h3 mark{background:rgba(255,176,32,.28);color:inherit;border-radius:3px;padding:0 2px}
  .card .excerpt{margin:0;font-size:13.5px;color:var(--muted);flex:1}
  .card .go{font-size:12.5px;font-weight:700;color:var(--accent)}
  .relnote{font-size:12px;color:var(--accent2);font-weight:600}
  .status{text-align:center;padding:60px 20px;color:var(--muted)}
  .status .big{font-size:20px;color:var(--txt);margin-bottom:8px}
  footer{margin-top:50px;text-align:center;color:var(--muted);font-size:12.5px;border-top:1px solid var(--line);padding-top:22px}

  .modal{position:fixed;inset:0;background:rgba(4,7,14,.82);backdrop-filter:blur(6px);display:none;align-items:center;justify-content:center;z-index:60}
  .modal.open{display:flex}
  .sheet{background:var(--card2);border:1px solid var(--line);border-radius:18px;width:100%;max-width:520px;max-height:82vh;overflow-y:auto;padding:22px}
  .sheet h3{margin:2px 0 16px;font-size:19px}
  .setrow{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid var(--line);font-size:14px}
  .setrow:last-child{border-bottom:none}
  .toggle{width:46px;height:26px;border-radius:999px;border:1px solid var(--line);background:var(--card);position:relative;cursor:pointer;flex:0 0 auto}
  .toggle.on{background:var(--accent);border-color:var(--accent)}
  .toggle .knob{position:absolute;top:2px;left:2px;width:20px;height:20px;border-radius:50%;background:#fff;transition:.15s}
  .toggle.on .knob{left:22px}
  .srcgrid{display:flex;flex-wrap:wrap;gap:7px;margin-top:8px}
  .srctag{font-size:12px;padding:5px 10px;border-radius:999px;border:1px solid var(--line);background:var(--card);color:var(--muted);cursor:pointer}
  .srctag.on{border-color:var(--accent2);color:var(--accent2);background:rgba(18,214,165,.1)}
  .fsbtns{display:flex;gap:6px}
  .fsbtns button{width:34px;height:30px;border-radius:8px;border:1px solid var(--line);background:var(--card);color:var(--txt);cursor:pointer}
  .closebtn{margin-top:16px;width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);background:var(--accent);color:#fff;font-weight:700;font-size:14px;cursor:pointer}

  .reader-backdrop{position:fixed;inset:0;background:rgba(4,7,14,.82);backdrop-filter:blur(6px);display:none;align-items:flex-start;justify-content:center;z-index:50;padding:28px 14px;overflow-y:auto}
  .reader{position:relative;background:var(--card2);border:1px solid var(--line);border-radius:20px;max-width:820px;width:100%;padding:20px 30px 32px;box-shadow:0 30px 80px rgba(0,0,0,.6);margin-bottom:30px}
  .rbar{position:sticky;top:0;display:flex;justify-content:flex-end;gap:8px;z-index:2;padding:4px 0;margin:-6px 0 0}
  .rbtn{width:40px;height:40px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--txt);font-size:16px;cursor:pointer}
  .rbtn.on{border-color:var(--accent);color:#fff}
  .rbtn.fav.on{color:#ff4d6d;border-color:#ff4d6d}
  .rmeta{display:flex;gap:12px;align-items:center;font-size:12.5px;color:var(--muted);flex-wrap:wrap}
  .rmeta .badge{position:static}.rmeta .rsrc{font-weight:700;color:#aab6cf}
  .rmeta .tr{font-weight:600;color:var(--accent2);background:rgba(18,214,165,.12);border:1px solid rgba(18,214,165,.3);padding:2px 8px;border-radius:6px}
  .rtitle{font-size:25px;line-height:1.3;margin:12px 0 6px}
  .rtime{font-size:13px;color:var(--muted);margin:0 0 16px}
  .reader img{max-width:100%;border-radius:12px;margin:6px 0 16px;display:block}
  .reader p{font-size:15.5px;line-height:1.75;color:#d5dcec;margin:0 0 14px}
  .reader p mark,.reader h3 mark,.rtitle mark{background:rgba(255,176,32,.28);color:inherit;border-radius:3px;padding:0 2px}
  .reader h3{font-size:18.5px;margin:24px 0 10px;color:#fff}
  .rnote{color:var(--muted);font-style:italic}
  .rrelated{margin:16px 0;padding:12px 16px;background:var(--card);border:1px solid var(--line);border-radius:12px;font-size:13.5px}
  .rrelated .rl{color:var(--muted);font-weight:700;font-size:11px;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px}
  .rrelated a{color:var(--accent);text-decoration:none;margin-right:14px}
  .rsource{display:inline-block;margin-top:16px;color:var(--accent);font-weight:700;text-decoration:none;font-size:13.5px;border:1px solid var(--line);padding:9px 16px;border-radius:12px}
  @media(max-width:560px){.brand h1{font-size:26px}.headright{align-items:flex-start}}
  /* --- fonctions bonus --- */
  .card.crit{border-color:rgba(255,77,109,.6)}
  .alertpill{color:#ff4d6d;font-weight:800;font-size:10.5px;margin-right:5px}
  .menace{display:none;align-items:center;gap:6px;font-size:12px;font-weight:600;padding:5px 12px;border-radius:999px;border:1px solid var(--line);background:var(--card);color:var(--muted);margin-bottom:14px}
  .menace b{font-weight:800}
  .quiz{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:16px 18px;margin-bottom:14px;display:none}
  .quiz .lbl{font-size:11px;letter-spacing:2px;text-transform:uppercase;color:#b06bff;font-weight:800;margin-bottom:8px}
  .quiz .qq{font-size:15px;font-weight:600;margin-bottom:10px}
  .qopts{display:flex;flex-direction:column;gap:7px}
  .qopt{text-align:left;background:var(--card2);border:1px solid var(--line);color:var(--txt);border-radius:10px;padding:10px 12px;font-size:13.5px;cursor:pointer;font-family:inherit}
  .qopt:hover:not(:disabled){border-color:var(--accent)}
  .qopt.ok{border-color:#12d6a5;background:rgba(18,214,165,.12)}
  .qopt.ko{border-color:#ff4d6d;background:rgba(255,77,109,.12)}
  .qopt:disabled{cursor:default}
  .qexp{margin-top:10px;font-size:13px;color:var(--muted)}
  .tldr{background:rgba(18,214,165,.08);border:1px solid rgba(18,214,165,.3);border-radius:12px;padding:12px 16px;margin:0 0 16px}
  .tldr .tl{font-size:11px;font-weight:800;letter-spacing:1px;text-transform:uppercase;color:var(--accent2);margin-bottom:6px}
  .tldr ul{margin:0;padding-left:18px}.tldr li{margin:0 0 5px;font-size:14px;color:#cbd5ea}
  .gl{border-bottom:1px dashed var(--accent2);cursor:pointer}
  .glpop{position:fixed;z-index:80;max-width:290px;background:var(--card2);border:1px solid var(--accent2);border-radius:10px;padding:10px 13px;font-size:13px;line-height:1.5;color:var(--txt);box-shadow:0 10px 30px rgba(0,0,0,.5);display:none}
  .glpop b{color:var(--accent2);text-transform:capitalize}
  .podbar{position:fixed;left:0;right:0;bottom:0;z-index:65;background:var(--card2);border-top:1px solid var(--line);padding:10px 14px;display:none;align-items:center;gap:12px}
  .podbar .pt{flex:1;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .podbar button{background:var(--accent);border:none;color:#fff;border-radius:8px;padding:8px 14px;font-weight:700;cursor:pointer}
  .toast{position:fixed;left:50%;bottom:90px;transform:translateX(-50%);background:var(--card2);border:1px solid var(--accent2);color:var(--txt);padding:10px 16px;border-radius:10px;font-size:13px;z-index:90;display:none;box-shadow:0 10px 30px rgba(0,0,0,.5)}
  .archday{margin-bottom:16px}
  .archdate{font-weight:700;font-size:14px;text-transform:capitalize;margin-bottom:6px;color:var(--accent2)}
  .archlink{display:block;color:var(--txt);text-decoration:none;padding:6px 0;border-bottom:1px solid var(--line);font-size:13.5px}
  .archlink span{color:var(--muted);font-size:12px}
  /* --- bannière de mise à jour --- */
  .updbar{display:none;align-items:center;justify-content:space-between;gap:14px;flex-wrap:wrap;background:linear-gradient(90deg,var(--accent),var(--accent2));color:#fff;padding:12px 18px;border-radius:14px;margin-bottom:16px;box-shadow:var(--shadow);font-size:14.5px}
  .updbar .ub-txt{display:flex;align-items:center;gap:7px}
  .updbar .ub-actions{display:flex;align-items:center;gap:9px;flex:0 0 auto}
  .updbar .ub-go{background:#fff;color:var(--accent);border:none;border-radius:10px;padding:8px 16px;font-weight:800;font-size:13.5px;cursor:pointer}
  .updbar .ub-x{background:rgba(255,255,255,.22);color:#fff;border:none;border-radius:10px;width:32px;height:32px;font-size:15px;cursor:pointer}
  :root[data-theme="light"]{--bg:#eef1f7;--card:#ffffff;--card2:#ffffff;--line:#dfe4ee;--txt:#1a2233;--muted:#5b6678;--shadow:0 6px 20px rgba(20,30,60,.08)}
  :root[data-theme="light"] .tldr li,:root[data-theme="light"] .tip p{color:#33404f}
  :root[data-theme="light"] .reader p{color:#2a3444}

</style>
</head>
<body>
<div class="wrap">
  <div id="updbar" class="updbar"></div>
  <header class="top">
    <div class="brand">
      <span class="kick"><span class="dot"></span> Édition du jour</span>
      <h1>🎮 Gaming Daily</h1>
    </div>
    <div class="headright">
      <div class="date">__DATEJOUR__</div>
      <div class="sub">Actualisé à __HEURE__ · lecture intégrée, sans pub · news anglaises traduites</div>
      <div class="hbtns">
        <button class="iconbtn" id="podBtn" title="Mode podcast">🎧</button><button class="iconbtn" id="ttsAllBtn" title="Écouter le résumé">🔊</button>
        <button class="iconbtn" id="themeBtn" title="Thème clair/sombre">☀️</button><button class="iconbtn" id="archBtn" title="Archives">📚</button><button class="iconbtn" id="setBtn" title="Réglages">⚙️</button>
      </div>
    </div>
  </header>

  <div class="searchbar"><input id="search" type="search" placeholder="🔍 Rechercher un jeu, une console, une source…" autocomplete="off"></div>

  <section class="tip">
    <div class="lbl">💡 Astuce gaming du jour</div>
    <h2 id="tipTitle">—</h2>
    <p id="tipText">—</p>
  </section>

  <section class="digest" id="digest" style="display:none">
    <div class="lbl">📌 Les infos à retenir</div>
    <ol id="digestList"></ol>
  </section>

  <div id="menace" class="menace"></div><section class="quiz" id="quiz"></section><div class="topics" id="topics"></div>

  <div class="filters" id="filters">
    <button class="chip active" data-cat="all">Tout</button>
    <button class="chip" data-cat="actu">🎮 Actu</button>
    <button class="chip" data-cat="console">🕹️ Consoles</button>
    <button class="chip" data-cat="pc">💻 PC</button>
    <button class="chip" data-cat="modding">🛠️ Modding &amp; Rétro</button>
    <button class="chip" data-cat="esport">⚔️ Esport</button>
    <button class="chip fav" data-cat="fav">❤️ Favoris</button>
  </div>
  <div class="count" id="count"></div>

  <div class="grid" id="grid"></div>
  <div class="status" id="status" style="display:none"></div>

  <footer>Articles extraits des flux publics des médias jeu vidéo — lecture sans publicité, news anglaises traduites en français.<br>Chaque article garde un lien vers sa source d’origine.</footer>
</div>

<div class="modal" id="setModal">
  <div class="sheet">
    <h3>⚙️ Réglages</h3>
    <div class="setrow"><span>Regrouper les articles en double</span><div class="toggle" id="tgCluster"><div class="knob"></div></div></div>
    <div class="setrow"><span>Taille du texte</span><div class="fsbtns"><button id="fsMinus">A−</button><button id="fsPlus">A+</button></div></div>
    <div style="padding:12px 0 4px;font-size:14px">Sources affichées <span style="color:var(--muted);font-size:12px">(clic pour masquer/afficher)</span></div>
    <div class="srcgrid" id="srcGrid"></div>
    <button class="closebtn" id="setClose">Terminé</button>
  </div>
</div>

<div class="reader-backdrop" id="readerBackdrop"><div class="reader" id="reader"></div></div>
<div id="glpop" class="glpop"></div>
<div id="toast" class="toast"></div>
<div class="podbar" id="podbar"><div class="pt"></div><button id="podStop">&#9209; Stop</button></div>
<div class="modal" id="archModal"><div class="sheet"><h3>&#128218; Archives</h3><div id="archBody"></div><button class="closebtn" id="archClose">Fermer</button></div></div>

<script>
var RAW = __NEWS_JSON__;
var APP_VERSION='__APP_VERSION__';
var GITHUB_REPO='wk0t/GamingDaily';
var PC_UPDATE=__UPDATE_JSON__;
var TIPS = [
  {t:"Active Steam Guard et la 2FA sur tes comptes de jeu",x:"Les comptes Steam, Epic, PSN ou Xbox pleins de jeux et de skins sont des cibles de choix. La double authentification (appli mobile) bloque la quasi-totalité des vols de compte, même si ton mot de passe fuite."},
  {t:"Ne précommande pas à l’aveugle",x:"Attends les tests et les retours des joueurs le jour de la sortie. Les bonus de précommande sont rarement intéressants, et un jeu cassé au lancement se corrige (ou pas) des mois plus tard."},
  {t:"Sauvegarde tes parties, pas seulement dans le cloud",x:"Steam Cloud peut écraser une sauvegarde corrompue. Copie de temps en temps tes dossiers de saves (Documents, AppData) sur un disque externe — surtout avant d’installer des mods."},
  {t:"Les skins « gratuits », c’est presque toujours une arnaque",x:"Générateurs de V-Bucks, sites de skins CS2, cadeaux Discord : ce sont des pièges à identifiants. Aucun site tiers ne peut te donner de la monnaie de jeu gratuite."},
  {t:"Joue en filaire pour réduire le lag",x:"Un câble Ethernet élimine les pertes de paquets du Wi-Fi et stabilise ton ping. Si c’est impossible, rapproche-toi de la box ou passe en Wi-Fi 5 GHz/6 GHz, et évite les téléchargements pendant tes parties."},
  {t:"Mets à jour tes pilotes graphiques",x:"NVIDIA et AMD publient des pilotes optimisés pour chaque grosse sortie, avec parfois +10 à 20 % de performances. GeForce Experience ou AMD Adrenalin le font en deux clics."},
  {t:"Compare les prix avant d’acheter",x:"IsThereAnyDeal.com te montre l’historique des prix d’un jeu sur toutes les boutiques officielles. La plupart des jeux sont à −50 % moins d’un an après leur sortie."},
  {t:"Méfie-toi des sites de clés pas chères",x:"Les clés du marché gris sont parfois achetées avec des cartes volées : l’éditeur peut les révoquer et tu perds le jeu. Privilégie les vendeurs officiels ou les soldes."},
  {t:"Installe tes jeux sur un SSD",x:"Les temps de chargement fondent et certains jeux récents streament leurs textures depuis le disque : sur un HDD, ça rame. Garde le SSD pour les jeux auxquels tu joues, archive le reste."},
  {t:"Dépoussière ta console et ton PC",x:"La poussière fait chauffer, et la chauffe fait baisser les performances (throttling) voire planter. Un coup de soufflette tous les 6 mois dans les aérations prolonge la vie de ta machine."},
  {t:"Active le VRR si ton écran le permet",x:"G-Sync, FreeSync ou VRR HDMI 2.1 synchronisent l’écran avec le jeu : fini les déchirures d’image et les saccades, même quand le framerate varie. Ça se règle une fois et ça change tout."},
  {t:"Modding : sauvegarde d’abord, et télécharge au bon endroit",x:"Avant d’installer des mods, copie tes saves et note ta version du jeu. Passe par des plateformes connues comme Nexus Mods ou le Workshop Steam — les .exe de mods inconnus cachent parfois des malwares."},
  {t:"Jailbreak et CFW : jamais avec ta console principale",x:"Modifier une console connectée au réseau (PSN, Nintendo eShop, Xbox Live), c’est le ban définitif du compte assuré. Les bidouilleurs utilisent une console dédiée, hors ligne, et gardent leurs achats ailleurs."},
  {t:"Désactive l’achat en un clic sur les stores",x:"Entre les monnaies virtuelles, les lootboxes et les DLC, la facture grimpe vite. Exige un mot de passe pour chaque achat — indispensable si des enfants jouent sur ta machine."},
  {t:"Limite le crossplay si tu subis les tricheurs",x:"Sur console, beaucoup de jeux permettent de désactiver le jeu croisé avec PC : tu affrontes alors uniquement des joueurs manette, où les cheats aimbot/wallhack sont beaucoup plus rares."}
];
(function(){var start=new Date(new Date().getFullYear(),0,0);var day=Math.floor((new Date()-start)/86400000);var tip=TIPS[day%TIPS.length];document.getElementById('tipTitle').textContent=tip.t;document.getElementById('tipText').textContent=tip.x;})();

function lsGet(k,def){try{var v=localStorage.getItem(k);return v==null?def:JSON.parse(v);}catch(e){return def;}}
function lsSet(k,v){try{localStorage.setItem(k,JSON.stringify(v));}catch(e){}}
var SETTINGS=lsGet('gmd_settings',{cluster:true,fontScale:1,disabled:[]});
var READ=lsGet('gmd_read',{}),FAV=lsGet('gmd_fav',{}),TOPICS=lsGet('gmd_topics',[]);
document.documentElement.style.setProperty('--fs',SETTINGS.fontScale||1);

function fold(s){return (s||'').replace(/[‘’ʼ]/g,"'").normalize('NFD').replace(/[̀-ͯ]/g,'').toLowerCase();}
var CAT_LABEL={actu:"Actu",console:"Consoles",pc:"PC",modding:"Modding",esport:"Esport"};
var CAT_ICON={actu:"🎮",console:"🕹️",pc:"💻",modding:"🛠️",esport:"⚔️"};
var ALL=[],CURRENT='all',QUERY='';
function esc(s){var d=document.createElement('div');d.textContent=s||'';return d.innerHTML;}
function timeAgo(iso){if(!iso)return"";var d=new Date(iso);if(isNaN(d))return"";var s=(Date.now()-d.getTime())/1000;if(s<3600)return"il y a "+Math.max(1,Math.round(s/60))+" min";if(s<86400)return"il y a "+Math.round(s/3600)+" h";var days=Math.round(s/86400);return days<=1?"hier":"il y a "+days+" j";}
function readMins(a){if(a.mins)return a.mins;var w=0;var bd=bodyOf(a);if(bd.length){bd.forEach(function(b){if(b.t!=='img')w+=b.v.split(/\s+/).length;});}else{w=(a.excerpt||'').split(/\s+/).length*4;}a.mins=Math.max(1,Math.round(w/200));return a.mins;}
function matchesTopics(a){if(!TOPICS.length)return false;var t=fold(a.title+' '+a.excerpt);for(var i=0;i<TOPICS.length;i++){if(t.indexOf(fold(TOPICS[i]))>=0)return true;}return false;}
function markText(txt){var safe=esc(txt);if(!TOPICS.length)return safe;TOPICS.forEach(function(kw){if(!kw)return;var re=new RegExp('('+kw.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+')','gi');safe=safe.replace(re,'<mark>$1</mark>');});return safe;}
function titleTokens(t){var f=fold(t).replace(/[^a-z0-9 ]/g,' ').split(/\s+/).filter(function(w){return w.length>3;});var s={};f.forEach(function(w){s[w]=1;});return Object.keys(s);}
function jaccard(a,b){if(!a.length||!b.length)return 0;var setb={};b.forEach(function(w){setb[w]=1;});var inter=0;a.forEach(function(w){if(setb[w])inter++;});return inter/(a.length+b.length-inter);}
function cluster(list){if(!SETTINGS.cluster)return list.slice();var used=[],toks=list.map(function(a){return titleTokens(a.title);});for(var i=0;i<list.length;i++){if(used[i])continue;list[i].related=[];for(var j=i+1;j<list.length;j++){if(used[j]||list[i].source===list[j].source)continue;if(jaccard(toks[i],toks[j])>=0.55){list[i].related.push({source:list[j].source,link:list[j].link});used[j]=true;}}}return list.filter(function(a,i){return !used[i];});}

var grid=document.getElementById('grid'),statusEl=document.getElementById('status');
function findByLink(link){for(var i=0;i<RAW.length;i++){if(RAW[i].link===link)return RAW[i];}if(FAV[link])return FAV[link];return null;}
function visibleList(){
  var list;
  if(CURRENT==='fav'){list=Object.keys(FAV).map(function(k){return FAV[k];});}
  else{list=ALL.filter(function(a){return (CURRENT==='all'||a.cat===CURRENT)&&SETTINGS.disabled.indexOf(a.source)<0;});}
  if(QUERY){var q=fold(QUERY);list=list.filter(function(a){return fold(a.title+' '+a.excerpt+' '+a.source).indexOf(q)>=0;});}
  if(CURRENT!=='fav'){
    var dec=list.map(function(a,i){return {a:a,i:i,p:(TOPICS.length&&matchesTopics(a))?1:0,s:severityOf(a),b:sourceBoost(a)};});
    dec.sort(function(x,y){return (y.p-x.p)||(y.s-x.s)||(y.b-x.b)||(x.i-y.i);});
    list=dec.map(function(o){return o.a;});
  }
  updateMenace();
  return list;
}
function cardHtml(a){
  var b=a.cat||'actu',isFav=!!FAV[a.link],isRead=!!READ[a.link],isPin=(TOPICS.length&&matchesTopics(a)&&CURRENT!=='fav');var sv=severityOf(a);
  var thumb=a.img?"<img src='"+esc(a.img)+"' loading='lazy' referrerpolicy='no-referrer' alt='' onerror=\"this.parentNode.innerHTML='<div class=\\'noimg\\'>"+(CAT_ICON[b]||'')+"</div>'\">":"<div class='noimg'>"+(CAT_ICON[b]||'')+"</div>";
  var tr=a.translated?"<span class='tr'>🌐 traduit</span>":"";
  var rel=(a.related&&a.related.length)?"<span class='relnote'>+ "+a.related.length+" source"+(a.related.length>1?'s':'')+"</span>":"";
  return "<a class='card"+(isRead?' read':'')+(isPin?' pin':'')+(sv===2?' crit':'')+"' data-link='"+esc(a.link)+"'>"+
    "<div class='thumb'><span class='badge b-"+b+"'>"+(CAT_LABEL[b]||'News')+"</span>"+thumb+
      "<button class='heart"+(isFav?' on':'')+"' data-fav='"+esc(a.link)+"'>"+(isFav?'♥':'♡')+"</button>"+(isPin?"<span class='pinstar'>⭐</span>":"")+"</div>"+
    "<div class='body'><div class='src'><span class='name'>"+(sv===2?"<span class='alertpill'>🔥 À la une</span>":"")+esc(a.source)+tr+"</span><span class='meta'>"+readMins(a)+" min · "+timeAgo(a.date)+"</span></div>"+
    "<h3>"+markText(a.title)+"</h3><p class='excerpt'>"+esc(a.excerpt)+(a.excerpt&&a.excerpt.length>=180?'…':'')+"</p>"+
    "<div class='src'>"+rel+"<span class='go'>Lire ici →</span></div></div></a>";
}
function render(){
  var list=visibleList();
  document.getElementById('count').textContent=list.length+' article'+(list.length>1?'s':'')+(CURRENT==='fav'?' en favori':'');
  if(!list.length){grid.innerHTML='';statusEl.style.display='block';statusEl.innerHTML=CURRENT==='fav'?"<div class='big'>Aucun favori</div><div>Clique le ♡ d’un article pour le sauvegarder.</div>":"<div class='big'>Aucun article</div><div>Essaie une autre rubrique ou recherche.</div>";return;}
  statusEl.style.display='none';grid.innerHTML=list.map(cardHtml).join('');
}
function renderDigest(){var d=document.getElementById('digest'),ol=document.getElementById('digestList');if(!ALL.length){d.style.display='none';return;}var top=ALL.slice(0,3);ol.innerHTML=top.map(function(a){return "<li data-link='"+esc(a.link)+"'><b>"+esc(a.title)+"</b> <span>— "+esc(a.source)+"</span></li>";}).join('');d.style.display='block';}
function renderTopics(){var el=document.getElementById('topics');var h="<span class='tlab'>Sujets suivis :</span>";TOPICS.forEach(function(kw){h+="<span class='topic'>"+esc(kw)+"<b data-deltopic='"+esc(kw)+"'>✕</b></span>";});h+="<span class='topic-add' id='addTopic'>+ suivre un sujet</span>";el.innerHTML=h;}

/* Synthèse vocale (Web Speech) */
var speaking=false;
function speak(text){stopSpeak();if(window.speechSynthesis){var u=new SpeechSynthesisUtterance(text);u.lang='fr-FR';u.onend=function(){speaking=false;syncTts();if(window.onSpeakDone)window.onSpeakDone();};speechSynthesis.speak(u);speaking=true;syncTts();}}
function stopSpeak(){if(window.speechSynthesis)speechSynthesis.cancel();speaking=false;syncTts();}
function syncTts(){var b=document.getElementById('ttsAllBtn');if(b)b.classList.toggle('on',speaking);var rb=document.getElementById('rTts');if(rb)rb.classList.toggle('on',speaking);}

/* Lecteur */
var backdrop=document.getElementById('readerBackdrop'),readerEl=document.getElementById('reader'),readerOpen=false,readerCur=null;
function baseU(u){return(u||'').split('?')[0].replace(/-\d+x\d+(\.\w+)$/,'$1');}
function renderReader(a){
  var isFav=!!FAV[a.link];
  var h='<div class="rbar"><button class="rbtn'+(speaking?' on':'')+'" id="rTts" onclick="toggleReadAloud()">🔊</button><button class="rbtn" onclick="shareArticle(readerCur)" title="Partager">↗</button><button class="rbtn" onclick="voteSource(readerCur.source,1);toast(\'Plus de \'+readerCur.source)">👍</button><button class="rbtn" onclick="voteSource(readerCur.source,-1);toast(\'Moins de \'+readerCur.source)">👎</button><button class="rbtn fav'+(isFav?' on':'')+'" onclick="toggleFav(readerCur)">'+(isFav?'♥':'♡')+'</button><button class="rbtn" onclick="closeReader()">✕</button></div>';
  h+='<div class="rmeta"><span class="badge b-'+(a.cat||'actu')+'">'+(CAT_LABEL[a.cat]||'News')+'</span><span class="rsrc">'+esc(a.source)+'</span><span>'+timeAgo(a.date)+'</span>'+(a.translated?'<span class="tr">🌐 traduit de l’anglais</span>':'')+'</div>';
  h+='<h2 class="rtitle">'+markText(a.title)+'</h2><div class="rtime">⏱ '+readMins(a)+' min de lecture</div>';
  if(a.img)h+='<img src="'+esc(a.img)+'" referrerpolicy="no-referrer" onerror="this.remove()">';
  var seen=[baseU(a.img)];
  var bd=bodyOf(a);if(bd.length){bd.forEach(function(bk){if(bk.t==='img'){var kk=baseU(bk.v);if(seen.indexOf(kk)===-1){seen.push(kk);h+='<img src="'+esc(bk.v)+'" loading="lazy" referrerpolicy="no-referrer" onerror="this.remove()">';}}else if(bk.t==='h'){h+='<h3>'+markText(bk.v)+'</h3>';}else{h+='<p>'+markText(bk.v)+'</p>';}});}
  else{h+='<p>'+esc(a.excerpt)+'…</p><p class="rnote">Le contenu complet n’a pas pu être extrait — ouvre l’article sur le site d’origine ci-dessous.</p>';}
  if(a.related&&a.related.length){h+='<div class="rrelated"><div class="rl">Aussi couvert par</div>';a.related.forEach(function(r){h+='<a href="'+esc(r.link)+'" target="_blank" rel="noopener">'+esc(r.source)+' ↗</a>';});h+='</div>';}
  h+='<br><a class="rsource" href="'+esc(a.link)+'" target="_blank" rel="noopener">Source : '+esc(a.source)+' ↗</a>';
  readerEl.innerHTML=h;enhanceReader();
}
function openReaderLink(link){var a=findByLink(link);if(!a)return;readerOpen=true;readerCur=a;if(!READ[a.link]){READ[a.link]=1;lsSet('gmd_read',READ);}backdrop.style.display='flex';document.body.style.overflow='hidden';backdrop.scrollTop=0;renderReader(a);}
function closeReader(){readerOpen=false;readerCur=null;stopSpeak();backdrop.style.display='none';document.body.style.overflow='';render();}
function toggleReadAloud(){if(speaking){stopSpeak();return;}var a=readerCur;if(!a)return;var parts=[a.title];if(a.body)a.body.forEach(function(b){if(b.t!=='img')parts.push(b.v);});else parts.push(a.excerpt);speak(parts.join('. '));}
function snapshot(a){return{title:a.title,link:a.link,excerpt:a.excerpt,img:a.img,source:a.source,cat:a.cat,date:a.date,translated:a.translated,body:a.body||[],related:a.related||null,mins:a.mins||0};}
function toggleFav(a){if(!a)return;if(FAV[a.link])delete FAV[a.link];else FAV[a.link]=snapshot(a);lsSet('gmd_fav',FAV);if(readerOpen&&readerCur===a)renderReader(a);render();}
function addTopic(){var kw=prompt('Suivre un sujet (ex : Zelda, PS5, GTA 6, speedrun) :');if(kw==null)return;kw=kw.trim();if(!kw)return;if(TOPICS.map(function(x){return x.toLowerCase();}).indexOf(kw.toLowerCase())<0){TOPICS.push(kw);lsSet('gmd_topics',TOPICS);}renderTopics();render();}
function delTopic(kw){TOPICS=TOPICS.filter(function(x){return x!==kw;});lsSet('gmd_topics',TOPICS);renderTopics();render();}
function openSettings(){document.getElementById('tgCluster').classList.toggle('on',SETTINGS.cluster);var names={};RAW.forEach(function(a){names[a.source]=1;});var g=document.getElementById('srcGrid');g.innerHTML=Object.keys(names).sort().map(function(n){var on=SETTINGS.disabled.indexOf(n)<0;return "<span class='srctag"+(on?' on':'')+"' data-src='"+esc(n)+"'>"+esc(n)+"</span>";}).join('');document.getElementById('setModal').classList.add('open');}
function closeSettings(){document.getElementById('setModal').classList.remove('open');}
function applyFont(){document.documentElement.style.setProperty('--fs',SETTINGS.fontScale);lsSet('gmd_settings',SETTINGS);}
function rebuild(){ALL=cluster(RAW.slice());render();renderDigest();saveHistory();}

document.getElementById('search').addEventListener('input',function(e){QUERY=e.target.value;render();});
document.getElementById('filters').addEventListener('click',function(e){var c=e.target.closest('.chip');if(!c)return;var chips=document.querySelectorAll('.chip');for(var i=0;i<chips.length;i++)chips[i].classList.remove('active');c.classList.add('active');CURRENT=c.dataset.cat;render();});
grid.addEventListener('click',function(e){var fav=e.target.closest('.heart');if(fav){e.preventDefault();e.stopPropagation();toggleFav(findByLink(fav.getAttribute('data-fav')));return;}var card=e.target.closest('a.card');if(!card)return;e.preventDefault();openReaderLink(card.getAttribute('data-link'));});
document.getElementById('digest').addEventListener('click',function(e){var li=e.target.closest('li');if(li)openReaderLink(li.getAttribute('data-link'));});
document.getElementById('topics').addEventListener('click',function(e){if(e.target.id==='addTopic'){addTopic();return;}var del=e.target.getAttribute('data-deltopic');if(del)delTopic(del);});
document.getElementById('setBtn').addEventListener('click',openSettings);
document.getElementById('setClose').addEventListener('click',closeSettings);
document.getElementById('setModal').addEventListener('click',function(e){if(e.target.id==='setModal')closeSettings();});
document.getElementById('tgCluster').addEventListener('click',function(){SETTINGS.cluster=!SETTINGS.cluster;lsSet('gmd_settings',SETTINGS);this.classList.toggle('on',SETTINGS.cluster);rebuild();});
document.getElementById('fsPlus').addEventListener('click',function(){SETTINGS.fontScale=Math.min(1.4,(SETTINGS.fontScale||1)+0.1);applyFont();});
document.getElementById('fsMinus').addEventListener('click',function(){SETTINGS.fontScale=Math.max(0.85,(SETTINGS.fontScale||1)-0.1);applyFont();});
document.getElementById('srcGrid').addEventListener('click',function(e){var t=e.target.closest('.srctag');if(!t)return;var name=t.getAttribute('data-src');var i=SETTINGS.disabled.indexOf(name);if(i<0)SETTINGS.disabled.push(name);else SETTINGS.disabled.splice(i,1);lsSet('gmd_settings',SETTINGS);t.classList.toggle('on',SETTINGS.disabled.indexOf(name)<0);render();});
document.getElementById('ttsAllBtn').addEventListener('click',function(){if(speaking){stopSpeak();return;}var top=ALL.slice(0,5);if(!top.length)return;speak('Voici les infos à retenir. '+top.map(function(a,i){return (i+1)+'. '+a.title+'.';}).join(' '));});
document.addEventListener('keydown',function(e){if(e.key==='Escape'){if(document.getElementById('setModal').classList.contains('open'))closeSettings();else if(readerOpen)closeReader();}});
backdrop.addEventListener('click',function(e){if(e.target===backdrop)closeReader();});

renderTopics();
/* ============ Fonctions bonus (menace, glossaire, TL;DR, podcast, thème, votes, historique, partage, quiz) ============ */
var GLOSSARY={"fps":"Jeu de tir à la première personne (First-Person Shooter), où l’on voit à travers les yeux du personnage. Désigne aussi les images par seconde, qui mesurent la fluidité d’un jeu.","rpg":"Jeu de rôle : on incarne un personnage qui gagne de l’expérience, monte en niveau et s’équipe au fil d’une aventure souvent riche en histoire.","jrpg":"Jeu de rôle japonais, au style et à la narration typiques des productions nippones comme Final Fantasy ou Dragon Quest.","mmo":"Jeu massivement multijoueur en ligne, où des milliers de joueurs partagent le même monde persistant, comme World of Warcraft.","moba":"Arène de bataille en ligne où deux équipes de héros s’affrontent pour détruire la base adverse, comme League of Legends ou Dota 2.","battle royale":"Mode où des dizaines de joueurs s’affrontent sur une carte qui rétrécit, jusqu’au dernier survivant, comme Fortnite ou Warzone.","roguelike":"Jeu où l’on recommence de zéro à chaque mort, avec des niveaux générés aléatoirement : chaque partie est différente.","metroidvania":"Jeu d’exploration où de nouvelles capacités débloquent peu à peu des zones inaccessibles, dans la lignée de Metroid et Castlevania.","soulslike":"Jeu d’action exigeant inspiré de Dark Souls : combats punitifs, mort qui coûte cher, et grande satisfaction à progresser.","aaa":"Jeu à très gros budget produit par un grand studio, l’équivalent du blockbuster au cinéma.","dlc":"Contenu téléchargeable vendu après la sortie d’un jeu : nouvelles missions, personnages, cartes ou cosmétiques.","season pass":"Formule qui donne accès d’avance à plusieurs contenus futurs d’un jeu, généralement moins cher que de les acheter un par un.","battle pass":"Système de récompenses par paliers à débloquer en jouant pendant une saison, avec une piste gratuite et une piste payante.","free-to-play":"Jeu gratuit au téléchargement, qui se finance par les achats intégrés : cosmétiques, battle pass ou monnaie virtuelle.","pay-to-win":"Jeu où payer procure un avantage réel sur les autres joueurs, au-delà du simple cosmétique. Très mal vu par les joueurs.","microtransaction":"Petit achat en argent réel dans un jeu : skins, monnaie virtuelle, boosts. Le cœur du modèle économique des jeux gratuits.","lootbox":"Coffre au contenu aléatoire acheté avec de l’argent réel ou de la monnaie de jeu, critiqué pour sa proximité avec les jeux d’argent.","gacha":"Système de tirage aléatoire payant, hérité des jeux mobiles japonais, pour obtenir des personnages ou objets rares, comme dans Genshin Impact.","skin":"Objet purement cosmétique qui change l’apparence d’un personnage ou d’une arme sans modifier ses performances.","cross-play":"Possibilité de jouer ensemble en ligne depuis des machines différentes : PC, PlayStation, Xbox ou Switch.","crossplay":"Possibilité de jouer ensemble en ligne depuis des machines différentes : PC, PlayStation, Xbox ou Switch.","early access":"Jeu vendu avant d’être terminé : on y joue pendant son développement et il s’améliore au fil des mises à jour.","accès anticipé":"Jeu vendu avant d’être terminé : on y joue pendant son développement et il s’améliore au fil des mises à jour.","bêta":"Version de test d’un jeu, ouverte à tous ou sur invitation, qui sert à corriger bugs et serveurs avant la vraie sortie.","patch":"Mise à jour qui corrige des bugs, rééquilibre le jeu ou ajoute du contenu.","day one":"Se dit du jour de sortie d’un jeu. Le « patch day one » est la mise à jour à télécharger dès le lancement pour corriger les derniers problèmes.","nerf":"Affaiblissement volontaire d’une arme, d’un personnage ou d’une capacité jugés trop forts, via une mise à jour d’équilibrage.","buff":"Renforcement d’une arme, d’un personnage ou d’une capacité jugés trop faibles — l’inverse du nerf.","hitbox":"Zone invisible autour d’un personnage qui détermine ce qui compte comme une touche. Une hitbox mal réglée rend les combats injustes.","lag":"Décalage entre ton action et sa prise en compte par le jeu, causé par une connexion lente ou un serveur surchargé.","ping":"Temps en millisecondes que met un message à faire l’aller-retour vers le serveur. Plus il est bas, plus le jeu en ligne est réactif.","netcode":"Ensemble des techniques qui synchronisent une partie en ligne entre les joueurs. Un bon netcode masque le lag ; un mauvais fait rager.","matchmaking":"Système qui compose automatiquement les parties en ligne en réunissant des joueurs de niveau proche.","meta":"Ensemble des stratégies, armes ou personnages considérés comme les plus efficaces du moment dans un jeu compétitif.","farming":"Répéter une activité du jeu (tuer des monstres, refaire une mission) pour accumuler ressources, expérience ou objets.","speedrun":"Discipline qui consiste à finir un jeu le plus vite possible, en exploitant chaque raccourci et parfois des glitchs, chrono à l’appui.","glitch":"Bug du jeu détourné par les joueurs pour traverser un mur, dupliquer des objets ou sauter une partie du niveau.","rng":"Part de hasard générée par le jeu (butin, coups critiques, drops). « Bon RNG » = chanceux, « mauvais RNG » = malchanceux.","pvp":"Joueur contre joueur : les affrontements opposent de vraies personnes, en duel ou en équipes.","pve":"Joueur contre environnement : on affronte des ennemis contrôlés par le jeu, seul ou en coopération.","hud":"Interface affichée à l’écran pendant le jeu : vie, munitions, mini-carte. Un bon HUD informe sans gêner.","ray tracing":"Technique de rendu qui simule le trajet réel de la lumière pour des reflets et des ombres réalistes. Magnifique, mais gourmand en puissance.","dlss":"Technologie NVIDIA qui utilise l’IA pour afficher le jeu en haute définition à partir d’une image calculée en plus basse résolution : gros gain de performances.","cloud gaming":"Jouer en streaming à des jeux qui tournent sur des serveurs distants, sans installation, comme avec GeForce Now ou le cloud Xbox.","remaster":"Version améliorée d’un ancien jeu : textures, résolution et confort modernisés, mais le jeu reste le même.","remake":"Jeu ancien entièrement refait de zéro avec les technologies actuelles, comme Resident Evil 4 ou Final Fantasy VII Remake.","émulateur":"Logiciel qui imite une console sur un autre appareil (PC, téléphone) pour lancer ses jeux. Légal, tant qu’on possède les jeux originaux.","rom":"Copie numérique d’un jeu (cartouche ou disque) utilisée par les émulateurs. Télécharger des ROM de jeux qu’on ne possède pas est illégal.","romhack":"Version modifiée d’un jeu rétro créée par des fans : nouveaux niveaux, traductions, difficultés inédites.","homebrew":"Application ou jeu amateur non officiel qui tourne sur une console, généralement après l’avoir débridée.","custom firmware":"Système modifié installé sur une console pour la débrider : il ouvre la porte aux homebrews, mais expose au bannissement en ligne.","jailbreak":"Débridage d’une console ou d’un appareil pour contourner les restrictions du fabricant et installer des logiciels non autorisés.","rétrocompatibilité":"Capacité d’une console à faire tourner les jeux des générations précédentes.","anticheat":"Logiciel de protection qui détecte et bannit les tricheurs dans les jeux en ligne, comme Easy Anti-Cheat ou BattlEye.","aimbot":"Triche qui vise automatiquement à la place du joueur dans les jeux de tir. Sa détection entraîne un bannissement.","crunch":"Période de surtravail intense imposée aux équipes pour finir un jeu à temps, régulièrement dénoncée dans l’industrie.","portage":"Adaptation d’un jeu vers une autre machine que celle d’origine, par exemple un jeu console qui arrive sur PC.","exclusivité":"Jeu disponible sur une seule plateforme, arme commerciale majeure entre PlayStation, Xbox et Nintendo.","moteur de jeu":"Logiciel qui fait tourner le jeu : graphismes, physique, sons. Les plus connus sont l’Unreal Engine et Unity.","open world":"Jeu en monde ouvert : une grande carte explorable librement, sans couloirs imposés, comme dans GTA ou Zelda.","monde ouvert":"Grande carte explorable librement, sans couloirs imposés, comme dans GTA ou Breath of the Wild.","indé":"Jeu indépendant créé par un petit studio sans gros éditeur, souvent plus original et moins cher qu’un AAA."};
var GLOSS_KEYS=Object.keys(GLOSSARY).sort(function(a,b){return b.length-a.length;});
var QUIZ=[{"q":"Quelle est la console la plus vendue de l'histoire ?","options":["La PlayStation 2","La Wii","La Game Boy"],"correct":0,"explain":"La PS2 s'est écoulée à environ 160 millions d'exemplaires depuis 2000, un record que la Switch talonne aujourd'hui."},{"q":"Qui a créé Mario ?","options":["Hideo Kojima","Shigeru Miyamoto","Satoru Iwata"],"correct":1,"explain":"Shigeru Miyamoto a créé Mario, mais aussi Zelda et Donkey Kong. C'est le game designer le plus influent de l'histoire de Nintendo."},{"q":"Dans quel jeu Mario apparaît-il pour la première fois ?","options":["Super Mario Bros.","Mario Kart","Donkey Kong (1981)"],"correct":2,"explain":"Mario débute en 1981 dans Donkey Kong sous le nom de « Jumpman », avant d'avoir sa propre série en 1985 avec Super Mario Bros."},{"q":"Que signifie « RPG » ?","options":["Role-Playing Game, un jeu de rôle","Real Player Game","Rapid Pixel Graphics"],"correct":0,"explain":"Dans un RPG, on incarne un personnage qui progresse : niveaux, équipement, choix d'histoire. Exemples : Final Fantasy, Baldur's Gate."},{"q":"À qui appartient la boutique Steam ?","options":["Microsoft","Valve","Epic Games"],"correct":1,"explain":"Valve, le studio de Half-Life et Counter-Strike, a lancé Steam en 2003. C'est aujourd'hui la plus grande boutique de jeux PC."},{"q":"Qu'est-ce qu'un speedrun ?","options":["Un mode de difficulté extrême","Une course dans un jeu de voitures","Finir un jeu le plus vite possible, chrono en main"],"correct":2,"explain":"Les speedrunners optimisent chaque seconde, parfois à l'aide de glitchs. Les records sont vérifiés et classés par catégories sur speedrun.com."},{"q":"Qu'est-ce qu'un émulateur ?","options":["Un logiciel qui imite une console pour lancer ses jeux ailleurs","Un programme anti-triche","Une manette compatible toutes consoles"],"correct":0,"explain":"Un émulateur reproduit le fonctionnement d'une console sur PC ou téléphone. L'outil est légal ; télécharger des jeux qu'on ne possède pas ne l'est pas."},{"q":"Que risque une console débridée (jailbreak/CFW) utilisée en ligne ?","options":["Rien du tout","Un bannissement définitif des services en ligne","Juste un avertissement par e-mail"],"correct":1,"explain":"Nintendo, Sony et Microsoft détectent les consoles modifiées et bannissent console et compte. Les bidouilleurs gardent une machine dédiée hors ligne."},{"q":"Que signifie « free-to-play » (F2P) ?","options":["Un jeu jouable gratuitement, financé par les achats intégrés","Un jeu offert avec une console","Un week-end d'essai gratuit"],"correct":0,"explain":"Fortnite, Warzone ou League of Legends sont gratuits : skins, battle pass et monnaies virtuelles font leur chiffre d'affaires."},{"q":"Quelle est la mascotte de SEGA ?","options":["Pac-Man","Pikachu","Sonic"],"correct":2,"explain":"Sonic le hérisson est né en 1991 pour concurrencer Mario, à l'époque où SEGA fabriquait encore des consoles comme la Mega Drive."},{"q":"Dans la série Zelda, comment s'appelle le héros que l'on incarne ?","options":["Link","Zelda","Ganon"],"correct":0,"explain":"Piège classique : Zelda est la princesse, Ganon le méchant. Le héros en tunique verte s'appelle Link."},{"q":"Qu'est-ce qu'un « nerf » dans un jeu ?","options":["Un bug d'affichage","L'affaiblissement d'une arme ou d'un personnage trop forts","Un bonus d'expérience temporaire"],"correct":1,"explain":"Quand un élément domine la meta, les développeurs le « nerfent » via un patch d'équilibrage. L'inverse (renforcer) s'appelle un buff."},{"q":"Qu'est-ce que le cross-play ?","options":["Jouer à deux sur le même écran","Changer de personnage en pleine partie","Jouer ensemble depuis des plateformes différentes (PC, consoles)"],"correct":2,"explain":"Le cross-play réunit les joueurs PC, PlayStation, Xbox et Switch dans les mêmes parties, comme dans Fortnite ou Rocket League."},{"q":"Qu'est-ce qu'une ROM ?","options":["La copie numérique d'un jeu, lisible par un émulateur","Une pièce détachée de console","Un format de carte mémoire"],"correct":0,"explain":"La ROM contient les données du jeu extraites de la cartouche ou du disque. On ne peut légalement utiliser que celles de jeux qu'on possède."},{"q":"À quoi sert le DLSS de NVIDIA ?","options":["À refroidir la carte graphique","À gagner des performances grâce à l'upscaling par IA","À bloquer les logiciels de triche"],"correct":1,"explain":"Le jeu est calculé en résolution réduite puis agrandi par IA : image quasi identique, mais beaucoup plus d'images par seconde. AMD propose le FSR."},{"q":"Quelle est la différence entre un remake et un remaster ?","options":["Aucune, c'est le même mot","Le remaster est toujours gratuit","Le remake est refait de zéro, le remaster améliore l'original"],"correct":2,"explain":"Un remaster lisse l'existant (textures, résolution). Un remake reconstruit le jeu entier avec les technologies modernes, comme Resident Evil 4 (2023)."},{"q":"Qu'est-ce qu'un roguelike ?","options":["Un jeu à niveaux générés aléatoirement où la mort fait tout recommencer","Un jeu d'infiltration","Un mode photo avancé"],"correct":0,"explain":"Chaque partie est unique et la mort est permanente : Hades, Balatro ou The Binding of Isaac reposent sur ce principe."},{"q":"Le Game Pass est le service d'abonnement de...","options":["PlayStation","Xbox (Microsoft)","Nintendo"],"correct":1,"explain":"Le Game Pass donne accès à un catalogue de jeux contre un abonnement mensuel, avec les exclusivités Xbox dès leur sortie. Sony répond avec le PS Plus."},{"q":"Qu'est-ce que le RNG ?","options":["Le moteur graphique d'un jeu","Le classement mondial des joueurs","La part de hasard générée par le jeu (butin, critiques...)"],"correct":2,"explain":"RNG = Random Number Generator. C'est lui qui décide du butin qui tombe ou des coups critiques — d'où « bon » ou « mauvais » RNG."},{"q":"Qui a créé Minecraft à l'origine ?","options":["Markus « Notch » Persson","Electronic Arts","Ubisoft"],"correct":0,"explain":"Développé seul par Notch en 2009 puis par son studio Mojang, Minecraft a été racheté par Microsoft en 2014 pour 2,5 milliards de dollars."},{"q":"Qu'est-ce qu'un homebrew sur console ?","options":["Une boisson énergisante d'esport","Une application ou un jeu amateur non officiel","Un pack de textures officiel"],"correct":1,"explain":"Les homebrews sont créés par des passionnés et tournent sur des consoles débridées : émulateurs, utilitaires, jeux inédits."},{"q":"Hideo Kojima est le créateur de...","options":["Metal Gear Solid et Death Stranding","Super Mario","FIFA"],"correct":0,"explain":"Figure du jeu vidéo japonais, Kojima a inventé le genre infiltration moderne avec Metal Gear avant de fonder son propre studio, Kojima Productions."},{"q":"Qu'est-ce que le « pay-to-win » ?","options":["Gagner de l'argent en jouant","Un tournoi à inscription payante","Quand payer donne un avantage réel sur les autres joueurs"],"correct":2,"explain":"Un jeu est pay-to-win quand l'argent achète de la puissance (armes, stats) et pas seulement du cosmétique. C'est très critiqué par les joueurs."},{"q":"Une hitbox, c'est...","options":["La zone invisible qui détermine si un coup touche","Une boîte collector","Le menu des paramètres"],"correct":0,"explain":"Chaque personnage ou objet a une zone de collision. Si elle est plus grande ou plus petite que le visuel, les touches semblent injustes."},{"q":"Qu'est-ce que l'esport ?","options":["Un sport olympique officiel","La compétition de jeu vidéo, avec équipes pro et tournois","Un jeu de sport en réalité virtuelle"],"correct":1,"explain":"League of Legends, Counter-Strike ou Rocket League ont des ligues professionnelles, des salaires, des transferts et des finales dans des stades."}];
var SEV={"critical":["nintendo direct","state of play","playstation showcase","xbox games showcase","xbox showcase","summer game fest","game awards","gamescom","rachat","rachete","acquisition","acquiert","acquires","buyout","fermeture du studio","fermeture de","ferme ses portes","licenciement","licenciements","layoffs","lays off","shuts down","shut down","faillite","bankruptcy","annule","annulation","cancelled","canceled","est reporte","reporte a","reporte en","repousse a","repousse en","delayed","fuite massive","leak massif","massive leak","gros leak","banwave","vague de ban","nouvelle console","next-gen","ps6","successeur de la switch","switch 3","hausse de prix","augmentation de prix","prix augmente","price increase","price hike","proces","lawsuit","surprise annonce","annonce surprise","officialise","record de ventes","million d'exemplaires","millions d'exemplaires","million de joueurs","millions de joueurs"],"important":["date de sortie","release date","beta ouverte","open beta","beta fermee","closed beta","early access","acces anticipe","mise a jour majeure","major update","patch notes","nouvelle extension","new expansion","dlc","season pass","crossplay","cross-play","demo disponible","demo jouable","free weekend","gratuit ce week-end","week-end gratuit","nouveau trailer","gameplay devoile","gameplay reveal","configurations requises","config requise"]};

function bodyOf(a){return a.body||a.blocks||[];}
function severityOf(a){
  if(a.sev!=null)return a.sev;
  var t=fold((a.title||'')+' '+(a.excerpt||''));
  var s=0,i;
  for(i=0;i<SEV.critical.length;i++){if(t.indexOf(SEV.critical[i])>=0){s=2;break;}}
  if(!s){for(i=0;i<SEV.important.length;i++){if(t.indexOf(SEV.important[i])>=0){s=1;break;}}}
  a.sev=s;return s;
}
function updateMenace(){
  var el=document.getElementById('menace');if(!el)return;
  var c=0;ALL.forEach(function(a){if(severityOf(a)===2)c++;});
  var L=c>=6?{t:'Actu en fusion',e:'🌋',c:'#ff4d6d'}:c>=3?{t:'Grosse journée',e:'🔥',c:'#ffb020'}:c>=1?{t:'Ça bouge',e:'⚡',c:'#ffb020'}:{t:'Journée calme',e:'🟢',c:'#12d6a5'};
  el.style.display='inline-flex';el.style.borderColor=L.c;el.innerHTML='<span>'+L.e+'</span> Hype du jour : <b style="color:'+L.c+'">'+L.t+'</b>'+(c?' ('+c+' gros titre'+(c>1?'s':'')+')':'');
}
var VOTES=lsGet('gmd_votes',{});
function voteSource(src,dir){VOTES[src]=(VOTES[src]||0)+dir;lsSet('gmd_votes',VOTES);}
function sourceBoost(a){var v=VOTES[a.source]||0;return v>3?3:(v<-3?-3:v);}

/* TL;DR extractif */
function sentencesOf(txt){var m=(txt||'').match(/[^.!?]+[.!?]+/g);return m?m:((txt&&txt.length>40)?[txt]:[]);}
function makeTLDR(a){
  var sents=[];
  var bd=bodyOf(a);if(bd.length){bd.forEach(function(b){if(b.t==='p'){sentencesOf(b.v).forEach(function(s){s=s.trim();if(s.length>45)sents.push(s);});}});}
  if(!sents.length&&a.excerpt)sents=[a.excerpt];
  if(sents.length<=3)return sents;
  var kw=['annonce','sortie','date','exclusi','gratuit','million','joueur','studio','console','nouveau','remake','remaster','report','rachat','mise a jour','disponible','revele','confirme'];
  var scored=sents.map(function(s,i){var sc=(sents.length-i)/sents.length;var f=fold(s);kw.forEach(function(w){if(f.indexOf(w)>=0)sc+=0.4;});return {s:s,sc:sc,i:i};});
  scored.sort(function(x,y){return y.sc-x.sc;});
  return scored.slice(0,3).sort(function(x,y){return x.i-y.i;}).map(function(o){return o.s;});
}

/* Glossaire : surligne les termes dans le lecteur (nœuds texte uniquement) */
function glossify(){
  if(!readerEl)return;
  var used={};
  var walker=document.createTreeWalker(readerEl,NodeFilter.SHOW_TEXT,null,false);
  var nodes=[],n;
  while(n=walker.nextNode()){var p=n.parentNode;if(p&&/^(P|H3|LI)$/.test(p.tagName)&&p.className.indexOf('rnote')<0)nodes.push(n);}
  nodes.forEach(function(tn){
    var txt=tn.nodeValue,low=fold(txt);
    for(var k=0;k<GLOSS_KEYS.length;k++){
      var term=GLOSS_KEYS[k];if(used[term])continue;
      var ft=fold(term),idx=low.indexOf(ft);if(idx<0)continue;
      var bfr=low.charAt(idx-1),aft=low.charAt(idx+ft.length);
      if(bfr&&/[a-z0-9éèàâê]/.test(bfr))continue;
      if(aft&&/[a-z0-9éèàâê]/.test(aft))continue;
      used[term]=1;
      var span=document.createElement('span');span.className='gl';span.setAttribute('data-t',term);span.textContent=txt.substr(idx,term.length);
      var post=document.createTextNode(txt.substr(idx+term.length));
      tn.nodeValue=txt.substr(0,idx);
      tn.parentNode.insertBefore(span,tn.nextSibling);
      tn.parentNode.insertBefore(post,span.nextSibling);
      break;
    }
  });
}
function showGloss(el){
  var t=el.getAttribute('data-t'),def=GLOSSARY[t];if(!def)return;
  var pop=document.getElementById('glpop');pop.innerHTML='<b>'+esc(t)+'</b><br>'+esc(def);
  var r=el.getBoundingClientRect();pop.style.display='block';
  var top=r.bottom+8,left=Math.min(r.left,window.innerWidth-300);
  pop.style.top=Math.min(top,window.innerHeight-120)+'px';pop.style.left=Math.max(8,left)+'px';
}
function hideGloss(){var p=document.getElementById('glpop');if(p)p.style.display='none';}

/* Enrichit le lecteur après chaque rendu : TL;DR + glossaire */
function enhanceReader(){
  var a=readerCur;if(!a||!readerEl)return;
  if(bodyOf(a).length){
    var tl=makeTLDR(a);
    if(tl.length){
      var box=document.createElement('div');box.className='tldr';
      box.innerHTML='<div class="tl">⚡ En bref</div><ul>'+tl.map(function(s){return '<li>'+esc(s)+'</li>';}).join('')+'</ul>';
      var anchor=readerEl.querySelector('.rtime');
      if(anchor)anchor.parentNode.insertBefore(box,anchor.nextSibling);
    }
  }
  glossify();
}

/* Mode podcast 🎧 */
var podcast={on:false,queue:[],idx:0};
function startPodcast(){
  var list=visibleList().slice(0,15);if(!list.length)return;
  podcast={on:true,queue:list,idx:0};playPodcast();
}
function playPodcast(){
  if(!podcast.on||podcast.idx>=podcast.queue.length){stopPodcast();return;}
  var a=podcast.queue[podcast.idx];
  var tl=(bodyOf(a).length)?makeTLDR(a).join(' '):a.excerpt;
  var bar=document.getElementById('podbar');
  if(bar){bar.style.display='flex';bar.querySelector('.pt').textContent='🎧 '+(podcast.idx+1)+'/'+podcast.queue.length+' — '+a.title;}
  speak('Article '+(podcast.idx+1)+'. '+a.title+'. '+(tl||''));
}
function stopPodcast(){podcast.on=false;stopSpeak();var bar=document.getElementById('podbar');if(bar)bar.style.display='none';}
window.onSpeakDone=function(){if(podcast.on){podcast.idx++;playPodcast();}else{speaking=false;syncTts();}};

/* Thème clair/sombre */
function applyTheme(){document.documentElement.setAttribute('data-theme',SETTINGS.theme||'dark');var b=document.getElementById('themeBtn');if(b)b.textContent=(SETTINGS.theme==='light')?'🌙':'☀️';}
function toggleTheme(){SETTINGS.theme=(SETTINGS.theme==='light')?'dark':'light';lsSet('gmd_settings',SETTINGS);applyTheme();}

/* Partage */
function toast(msg){var t=document.getElementById('toast');if(!t)return;t.textContent=msg;t.style.display='block';clearTimeout(window.__tt);window.__tt=setTimeout(function(){t.style.display='none';},2200);}
function shareArticle(a){
  if(!a)return;var text=a.title+' — '+a.link;
  if(window.AndroidBridge&&AndroidBridge.share){AndroidBridge.share(text);return;}
  if(navigator.share){navigator.share({title:a.title,url:a.link}).catch(function(){});return;}
  try{navigator.clipboard.writeText(text);toast('Lien copié !');}catch(e){window.prompt('Copie ce lien :',a.link);}
}

/* Historique / archives */
function saveHistory(){
  if(!ALL.length)return;
  var hist=lsGet('gmd_history',{});
  var key=new Date().toISOString().slice(0,10);
  hist[key]=ALL.slice(0,40).map(function(a){return {title:a.title,link:a.link,img:a.img,source:a.source,cat:a.cat,date:a.date,excerpt:a.excerpt};});
  var keys=Object.keys(hist).sort().reverse().slice(0,7);var trimmed={};keys.forEach(function(k){trimmed[k]=hist[k];});
  lsSet('gmd_history',trimmed);
}
function openArchives(){
  var hist=lsGet('gmd_history',{});var keys=Object.keys(hist).sort().reverse();
  var m=document.getElementById('archModal'),body=document.getElementById('archBody');
  if(!keys.length){body.innerHTML='<div style="color:var(--muted)">Aucun historique pour le moment. Reviens demain !</div>';}
  else{
    body.innerHTML=keys.map(function(k){
      var d=new Date(k+'T12:00:00').toLocaleDateString('fr-FR',{weekday:'long',day:'numeric',month:'long'});
      var arts=hist[k];
      return '<div class="archday"><div class="archdate">'+esc(d)+' <span style="color:var(--muted);font-weight:400">('+arts.length+')</span></div>'+
        arts.slice(0,12).map(function(a){return '<a class="archlink" href="'+esc(a.link)+'" target="_blank" rel="noopener">'+esc(a.title)+' <span>· '+esc(a.source)+'</span></a>';}).join('')+'</div>';
    }).join('');
  }
  m.classList.add('open');
}

/* Quiz du jour 🧠 */
function renderQuiz(){
  var el=document.getElementById('quiz');if(!el||!QUIZ.length)return;
  var start=new Date(new Date().getFullYear(),0,0);var day=Math.floor((new Date()-start)/86400000);
  var qi=day%QUIZ.length,q=QUIZ[qi];
  var answered=lsGet('gmd_quiz_'+qi,null);
  var h='<div class="lbl">🧠 Quiz gaming du jour</div><div class="qq">'+esc(q.q)+'</div><div class="qopts">';
  q.options.forEach(function(o,i){var cls='qopt';if(answered!=null){if(i===q.correct)cls+=' ok';else if(i===answered)cls+=' ko';}h+='<button class="'+cls+'" data-qi="'+i+'"'+(answered!=null?' disabled':'')+'>'+esc(o)+'</button>';});
  h+='</div>';
  if(answered!=null)h+='<div class="qexp">'+(answered===q.correct?'✅ Bravo ! ':'❌ ')+esc(q.explain)+'</div>';
  el.innerHTML=h;el.style.display='block';el.setAttribute('data-qi',qi);el.setAttribute('data-correct',q.correct);el.setAttribute('data-exp',q.explain);
}

/* ============ Mise à jour automatique (GitHub Releases) ============ */
function currentVersion(){
  try{ if(window.AndroidBridge&&AndroidBridge.appVersion){ var v=AndroidBridge.appVersion(); if(v) return v; } }catch(e){}
  return (typeof APP_VERSION!=='undefined')?APP_VERSION:'0';
}
function cmpVersion(a,b){
  // on retire un éventuel préfixe "v" et tout suffixe pré-release (-beta, -rc...)
  a=String(a).replace(/^v/i,'').split('-')[0].split('.');
  b=String(b).replace(/^v/i,'').split('-')[0].split('.');
  for(var i=0;i<Math.max(a.length,b.length);i++){
    var x=parseInt(a[i]||'0',10)||0,y=parseInt(b[i]||'0',10)||0;
    if(x>y)return 1; if(x<y)return -1;
  }
  return 0;
}
function showUpdateBanner(info){
  if(!info||!info.available||!info.version)return;
  if(lsGet('gmd_update_seen','')===info.version)return;   // déjà proposé puis masqué pour cette version
  var bar=document.getElementById('updbar');if(!bar)return;
  bar.innerHTML='<span class="ub-txt">🎉 <b>Gaming Daily '+esc(info.version)+'</b> est disponible</span>'+
    '<span class="ub-actions"><button class="ub-go" id="ubGo">Mettre à jour</button>'+
    '<button class="ub-x" id="ubX" title="Plus tard">✕</button></span>';
  bar.style.display='flex';
  document.getElementById('ubGo').onclick=function(){doUpdate(info);};
  document.getElementById('ubX').onclick=function(){lsSet('gmd_update_seen',info.version);bar.style.display='none';};
}
function doUpdate(info){
  var url=info.apk||info.url;
  if(window.AndroidBridge&&AndroidBridge.installUpdate&&info.apk){AndroidBridge.installUpdate(info.apk);toast('Téléchargement de la mise à jour…');return;}
  if(window.AndroidBridge&&AndroidBridge.openUrl){AndroidBridge.openUrl(url);return;}
  try{window.open(url,'_blank');}catch(e){location.href=url;}
}
function handleReleaseJson(raw){
  if(!raw)return;var j;try{j=JSON.parse(raw);}catch(e){return;}
  var tag=(j.tag_name||'').replace(/^v/i,'');if(!tag)return;
  if(cmpVersion(tag,currentVersion())>0){
    var apk=null;
    if(j.assets)for(var i=0;i<j.assets.length;i++){if(/\.apk$/i.test(j.assets[i].name||'')){apk=j.assets[i].browser_download_url;break;}}
    showUpdateBanner({available:true,version:tag,url:j.html_url,apk:apk});
  }
}
function checkForUpdate(){
  if(window.AndroidBridge&&AndroidBridge.fetchUrl){
    // Android : on interroge l'API GitHub via le pont natif (contourne CORS)
    bridgeFetch('https://api.github.com/repos/'+GITHUB_REPO+'/releases/latest').then(handleReleaseJson).catch(function(){});
  }else if(typeof PC_UPDATE!=='undefined'&&PC_UPDATE){
    // PC : l'info a déjà été calculée par le script PowerShell au démarrage
    showUpdateBanner(PC_UPDATE);
  }
}

function initFeatures(){
  applyTheme();
  renderQuiz();
  checkForUpdate();
  var tb=document.getElementById('themeBtn');if(tb)tb.addEventListener('click',toggleTheme);
  var pb=document.getElementById('podBtn');if(pb)pb.addEventListener('click',function(){if(podcast.on)stopPodcast();else startPodcast();});
  var ab=document.getElementById('archBtn');if(ab)ab.addEventListener('click',openArchives);
  var ps=document.getElementById('podStop');if(ps)ps.addEventListener('click',stopPodcast);
  var am=document.getElementById('archModal');if(am)am.addEventListener('click',function(e){if(e.target.id==='archModal'||e.target.id==='archClose')am.classList.remove('open');});
  var qz=document.getElementById('quiz');
  if(qz)qz.addEventListener('click',function(e){var b=e.target.closest('.qopt');if(!b||b.disabled)return;var qi=qz.getAttribute('data-qi');lsSet('gmd_quiz_'+qi,parseInt(b.getAttribute('data-qi'),10));renderQuiz();});
  document.addEventListener('click',function(e){var g=e.target.closest('.gl');if(g){showGloss(g);e.stopPropagation();}else{hideGloss();}});
  document.addEventListener('keydown',function(e){if(e.key==='Escape'){hideGloss();if(podcast.on)stopPodcast();var a=document.getElementById('archModal');if(a)a.classList.remove('open');}});
}

initFeatures();
rebuild();
</script>
</body>
</html>

'@

$html = $template.Replace('__NEWS_JSON__', $json).Replace('__DATEJOUR__', $dateJour).Replace('__HEURE__', $heure).Replace('__UPDATE_JSON__', $updateJson).Replace('__APP_VERSION__', $appVersion)
[System.IO.File]::WriteAllText($outFile, $html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host ("Magazine généré : {0} articles" -f $export.Count) -ForegroundColor Cyan
Start-Process $outFile
