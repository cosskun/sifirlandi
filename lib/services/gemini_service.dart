import 'dart:math';

/// SmartRoastEngine provides an autonomous, intelligent, 100% offline,
/// keyword-aware, duration-sensitive and contextual Turkish & English roast generator.
/// No API keys, zero configuration, zero latency.
class GeminiService {
  static final Random _random = Random();

  /// Generates a personalized, witty, and savage roast tailored to the user's note, duration, and context
  static Future<String> generateRoast({
    required String name,
    required String category,
    required String note,
    required String counterTitle,
    required String elapsedTimeFormatted,
    String lang = 'tr',
  }) async {
    // Artificial mini-delay (150ms) to give a satisfying natural feel
    await Future.delayed(const Duration(milliseconds: 150));

    final isTr = lang.toLowerCase() == 'tr';
    final cleanNote = note.trim();
    final lowerNote = cleanNote.toLowerCase();

    if (!isTr) {
      return _generateEnglishRoast(name, cleanNote, lowerNote, category, elapsedTimeFormatted);
    }

    return _generateTurkishRoast(name, cleanNote, lowerNote, category, elapsedTimeFormatted);
  }

  static String _generateTurkishRoast(
    String name,
    String note,
    String lowerNote,
    String category,
    String elapsedTime,
  ) {
    // 1. FAST FOOD & MEAT (Çiğ köfte, tantuni, döner, kebap, pizza, burger...)
    if (lowerNote.contains('çiğ köfte') || lowerNote.contains('cig kofte') || lowerNote.contains('dürüm') || lowerNote.contains('durum')) {
      return _pick([
        "Miden şu an bağımsızlığını ilan ediyor $name, gece siparişinle gurur duy! 🌯🔥",
        "Bir dürüm için $elapsedTime boyunca biriken iradeyi çöpe atmak tam sana göre $name! 🌶️",
        "Acılı dürümü görene kadarmış iraden $name... Yarın sabahki pişmanlığında başarılar! 🌯💀",
        "Lavaşın içine sarılmış $elapsedTime'lik emek... Afiyet olsun $name! 🌮🤦‍♂️",
      ]);
    }

    if (lowerNote.contains('pizza') || lowerNote.contains('burger') || lowerNote.contains('lahmacun') || lowerNote.contains('döner') || lowerNote.contains('kebap')) {
      return _pick([
        "Bir dilim yer bırakırım dedin, kutuyu bitirdin değil mi $name? $elapsedTime'lik rekor gitti! 🍕💀",
        "Fast food krizine $elapsedTime'lik emeğini kurban eden $name... Kaloriler sana selam duruyor! 🍔🍟",
        "Gitti $elapsedTime'lik diyet! Kokuyu alınca iradesini kaybeden $name klasiği... 🥩🔥",
      ]);
    }

    // 2. DESSERTS & SWEETS (Tatlı, baklava, künefe, çikolata, pasta...)
    if (lowerNote.contains('tatlı') || lowerNote.contains('tatli') || lowerNote.contains('pasta') || lowerNote.contains('çikolata') || lowerNote.contains('cikolata') || lowerNote.contains('künefe') || lowerNote.contains('kunefe') || lowerNote.contains('baklava')) {
      return _pick([
        "Şeker koması loading... $name yine bir tatlı krizine $elapsedTime'lik emeğini kurban etti! 🍰💉",
        "İraden tatlıyı görene kadarmış $name. Kaloriler şu an seninle halay çekiyor! 🍫🍩",
        "Künefenin peyniri uzadıkça senin irade kısaldı değil mi $name? 🍯🫠",
        "Bir çatal alıp bırakacaktın güya $name... Tabağı sıyırmışsın! 🎂👑",
      ]);
    }

    // 3. NIGHT & MIDNIGHT SNACKS (Gece, saat 3, buzdolabı, acıktım...)
    if (lowerNote.contains('gece') || lowerNote.contains('3') || lowerNote.contains('saat') || lowerNote.contains('buzdolabı') || lowerNote.contains('açlık') || lowerNote.contains('acıktım')) {
      return _pick([
        "Gece gelen o 'bir kereden bir şey olmaz' perileri yine seni kandırdı değil mi $name? 🦉👻",
        "Gece yarısı buzdolabının ışığında iradesini arayan ama bulamayan $name... 🌙👀",
        "Gece yapılan o gizli mutfak operasyonu $elapsedTime'lik seriyi yaktı $name! 🥪🚨",
      ]);
    }

    // 4. EX & RELATIONSHIP DRAMA (Eski sevgili, ex, mesaj, yazdım, aradım, stalk...)
    if (lowerNote.contains('eski') || lowerNote.contains('ex') || lowerNote.contains('mesaj') || lowerNote.contains('yazd') || lowerNote.contains('aradı') || lowerNote.contains('stalk') || lowerNote.contains('hikaye')) {
      return _pick([
        "Telefonu elinden almak için acil durum ilan etmemiz gerekecek $name! O mesaja yazıklar olsun... 📱🤦‍♂️",
        "Gitti $elapsedTime'lik gurur! Yine o 'nasılsın' mesajına yenik düştün $name... 💔🤡",
        "Stalk yaparken yanlışlıkla hikayesini beğenen $name draması... 🍿💀",
        "Aşk acısının şampiyonu $name: $elapsedTime dayandın ve yine yazdın! 🎪💔",
      ]);
    }

    // 5. SLEEP & LATENESS (Uyku, alarm, uyanamadım, geç kaldım, trafik, yoldayım...)
    if (lowerNote.contains('uyu') || lowerNote.contains('alarm') || lowerNote.contains('geç') || lowerNote.contains('gecik') || lowerNote.contains('yoldayım') || lowerNote.contains('trafik')) {
      return _pick([
        "Buluşma saati $name için sadece evrensel bir tavsiyeden ibaret! ⏰💤",
        "Alarm çaldığında '5 dakika daha' diyen $name, 3 saat sonra uyandı! 🛌🥱",
        "Yine 'yoldayım' dedin ve daha yataktan yeni kalktın değil mi $name? 🚶‍♂️🤦‍♂️",
        "Kronometreler ağlıyor, $name yine randevusuna yetişemedi! 🚨⏳",
      ]);
    }

    // 6. ACCIDENTS & CLUMSINESS (Kaza, sakarlık, kırdım, döktüm, çarptım, düşürdüm...)
    if (lowerNote.contains('kaza') || lowerNote.contains('sakar') || lowerNote.contains('kırdım') || lowerNote.contains('kırdı') || lowerNote.contains('döktüm') || lowerNote.contains('düşürdüm') || lowerNote.contains('çarptım')) {
      return _pick([
        "Sanayi ustaları dükkanın tapusunu $name üzerine yapmaya hazırlanıyor! 🚗🔧",
        "Yer çekimi ile kişisel bir davan var galiba $name, yine neyi devirdin? 💥🤦‍♂️",
        "Kasko şirketleri $name adını duyunca alarm veriyor! 💸🚗",
        "Kırıp dökmeden geçen $elapsedTime bir mucizeydi zaten $name! 🪟💀",
      ]);
    }

    // 7. GAMING & SOCIAL MEDIA (Oyun, valorant, lol, fifa, pes, tiktok, reels, dizi...)
    if (lowerNote.contains('oyun') || lowerNote.contains('maç') || lowerNote.contains('valorant') || lowerNote.contains('lol') || lowerNote.contains('fifa') || lowerNote.contains('pes') || lowerNote.contains('reels') || lowerNote.contains('tiktok') || lowerNote.contains('dizi')) {
      return _pick([
        "Bir el daha atıp yatacaktın güya $name... Güneş doğdu, tebrikler! 🎮🌅",
        "'Takım çok kötüydü' bahanesini geç $name, yenilgi senin kaderin olmuş! 🕹️💀",
        "Reels kaydırırken $elapsedTime'lik hayat enerjisini kaybeden $name... 📱😵‍💫",
      ]);
    }

    // 8. MONEY & SHOPPING (Para, trendyol, alışveriş, maaş, iddaa, harcadım...)
    if (lowerNote.contains('para') || lowerNote.contains('trendyol') || lowerNote.contains('alışveriş') || lowerNote.contains('sepet') || lowerNote.contains('maaş') || lowerNote.contains('iddaa') || lowerNote.contains('harcadım')) {
      return _pick([
        "Maaş yattığı an sepettekileri onaylayan $name, ayın geri kalanında taş yer artık! 💳💸",
        "Kargo kapıya gelince gelen o pişmanlık hissi... $elapsedTime'lik birikim bitti $name! 📦💀",
        "Tek maçtan yatan kupon gibi sıfırlandın $name! 🎫💸",
      ]);
    }

    // 9. COFFEE & HABITS (Kahve, sigara, nargile, çay...)
    if (lowerNote.contains('kahve') || lowerNote.contains('sigara') || lowerNote.contains('çay')) {
      return _pick([
        "'Bu sonuncuydu' yalanını kaçıncı kez söylüyorsun $name? 🚬⚠️",
        "Kahvesiz 2 saat duramayan $name, kafein bağımlılığında level atladı! ☕🧟‍♂️",
      ]);
    }

    // 10. WORK, STUDY & CODE (Kod, bug, ders, sınav, erteleme, patron...)
    if (lowerNote.contains('kod') || lowerNote.contains('bug') || lowerNote.contains('ders') || lowerNote.contains('sınav') || lowerNote.contains('ertele') || lowerNote.contains('çalış')) {
      return _pick([
        "'Yarın kesin başlıyorum' masalları serisi: Cilt 48, Yazar: $name! 📚😴",
        "Production'a cuma akşamı kod atan $name cesareti... Sistem çöktü! 💻🔥",
        "Ders çalışmamak için odasını baştan aşağı temizleyen $name klasiği! 🧹📖",
      ]);
    }

    // 11. CUSTOM INPUT SPECIFIC ROAST (Injects the custom note directly)
    if (note.isNotEmpty && !note.contains('Sebep belirtilmedi')) {
      return _pick([
        "'$note' bahanesini bulmak için çok düşündün mü $name? $elapsedTime'lik rekor tarihe karıştı! 🤦‍♂️🏆",
        "Gerekçe: '$note'... İrade seviyen şu an deniz seviyesinin altında $name! 📉🫠",
        "Dünya tarihinin en şüpheli bahanesi: '$note'! Tebrikler $name, alkışlar senin için! 👏💀",
        "'$note' diyerek $elapsedTime'lik emeği tek hamlede yakan koca yürekli $name! 🚨✍️",
        "Bahaneler kitabına yeni bir bölüm eklendi: '$note' (Yazar: $name). Gurur duy kendinle! 📖🤡",
      ]);
    }

    // 12. CATEGORY-BASED FALLBACK
    switch (category) {
      case 'diet':
        return _pick([
          "Diyet yalan oldu, yaşasın yemek yemek! $name yine dayanamadı 🍕",
          "$name diyeti sadece öğün aralarında yapıyor galiba! 🍩🥗",
          "Pazartesi başlanan diyetin hazin sonu. Tebrikler $name! 🍰🏆",
        ]);
      case 'clumsy':
        return _pick([
          "Kuru yer kalmamış galiba $name, yine mi sakarlık? 💥🤦‍♂️",
          "Yolların fatihi değil, sanayinin kralı $name! 👑🔧",
          "Gözü kapalı sürsen daha az kaza yapardın $name! 🚗💀",
        ]);
      case 'meeting':
        return _pick([
          "Yine mi geç kaldın $name? Şaşırdık mı? Tabii ki hayır! ⏰",
          "$name için buluşma saati sadece tatlı bir tavsiyedir. 🚶‍♂️💤",
          "Kronometreler ağlıyor, $name yine yola yeni çıkmış! ⏳🤦‍♂️",
        ]);
      case 'relationship':
        return _pick([
          "Yine mi aşk acısı, yine mi drama $name? 🍿💔",
          "Drama Queen/King tacını $name'e takdim ediyoruz! 👑🎬",
          "Aşk doktorları $name'in durumunu incelemekten emekli oldu! 💔🤡",
        ]);
      default:
        return _pick([
          "$elapsedTime sonra sıfırlanmak... Beklenen son gerçekleşti, şaşırmadık $name! 📉🤷‍♂️",
          "İrade dediğin şey $name için sadece bir kelimeden ibaretmiş! 🏆💀",
          "Kayıtlara geçsin: $name yine dayanamadı ve sayacı sıfırladı! 🚨✍️",
          "Tebrikler $name! Sıfırlanma rekorlar kitabında yeni bir sayfa açtın! 📖🤡",
        ]);
    }
  }

  static String _generateEnglishRoast(
    String name,
    String note,
    String lowerNote,
    String category,
    String elapsedTime,
  ) {
    if (note.isNotEmpty && !note.contains('No reason provided')) {
      return _pick([
        "Did you really reset a $elapsedTime streak for '$note', $name? Pure comedy! 🤡🤦‍♂️",
        "Reason: '$note'... Your willpower just dropped below zero, $name! 📉💀",
        "Congratulations $name! '$note' is officially the excuse of the year! 🏆👏",
      ]);
    }

    return _pick([
      "And just like that, $name's $elapsedTime streak went up in flames! 🔥💀",
      "We expected nothing and are still somehow disappointed in you, $name! 🤦‍♂️🏆",
      "Willpower level: 404 Not Found for $name! 🚨📉",
    ]);
  }

  static String _pick(List<String> items) {
    return items[_random.nextInt(items.length)];
  }
}
