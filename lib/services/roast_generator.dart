import 'dart:math';
import 'gemini_service.dart';

class RoastGenerator {
  static final _random = Random();

  static final Map<String, Map<String, List<String>>> _roasts = {
    'tr': {
      'clumsy': [
        "Kuru yer kalmış galiba {name}!",
        "Ah {name} vah {name}, yine mi sakarlık?",
        "Yine mi {name}?",
        "Kaskonun iflas hikayesi: Bölüm 44 💸💀",
        "{name}, arabayı yavaşça yere bırak ve ellerini direksiyondan çek! 🚫👐",
        "Kaza değil, {name}'in yol ile imtihanı... 🛣️🤦‍♂️",
        "Yolların fatihi değil, sanayinin kralı {name}! 👑🔧",
        "Gözü kapalı sürsen daha az kaza yapardın {name}! 🚗",
        "Seksek sekerek {name}...",
      ],
      'meeting': [
        "Yine mi geç kaldın {name}? Şaşırdık mı? Tabii ki hayır! ⏰",
        "{name} için buluşma saati sadece tatlı bir tavsiyedir.",
        "Kronometreler ağlıyor, {name} yine yola yeni çıkmış! 🚶‍♂️",
        "Yolu kaybettin galiba {name}, ya da yine uyuya kaldın?",
        "Bu kaç oldu {name}? Randevulara zamanında geldiğin gün bayram ilan edeceğiz!",
      ],
      'diet': [
        "Diyet yalan oldu, yaşasın yemek yemek! {name} yine dayanamadı 🍕",
        "{name} diyeti sadece öğün aralarında yapıyor galiba.",
        "Bir ısırıktan bir şey olmaz derken tepsiyi bitiren {name}...",
        "Kaloriler {name}'i görünce halay çekiyor! 🍰",
        "Pazartesi başlanan diyetin Salı günü hazin sonu. Tebrikler {name}!",
      ],
      'relationship': [
        "Yine mi aşk acısı, yine mi drama {name}? 🍿",
        "{name} sevgilisinden ayrıldı/barıştı... Aşk defterini kapatmanın vakti gelmedi mi?",
        "Aşk doktorları {name}'in durumunu incelemekten emekli oldu! 💔",
        "Drama Queen/King tacını {name}'e takdim ediyoruz! 👑",
        "Yine mi kavga? İlişki durumun: 'İsmail ile İmtihan' gibi karışık.",
      ],
      'custom': [
        "Yine mi {name}?",
        "Bu kaç oldu {name}?",
        "ah {name} vah {name}...",
        "Beklenen son gerçekleşti, şaşırmadık.",
        "Tebrikler {name}, bunu da başardın! 🏆",
      ],
    },
    'en': {
      'clumsy': [
        "Did you get your license from a cereal box, {name}? 🫨🚗",
        "Gravity seems to have a personal issue with you, {name}.",
        "Please step away from anything fragile, {name}! 🪟",
        "Insurance companies are crying right now because of {name}. 💸",
        "{name}, slowly put down the keys and step away from the vehicle! 🚫👐",
        "Not a crash, just {name}'s daily challenge with physics... 🛣️🤦‍♂️",
        "Not the king of the road, but definitely the king of repairs, {name}! 👑🔧",
        "You'd make fewer crashes driving with your eyes closed, {name}! 🚗",
      ],
      'meeting': [
        "Are you late again, {name}? We are shocked. Truly. ⏰",
        "For {name}, 'on my way' means 'I am still in bed'. 🛌",
        "Legend has it that {name} was once on time. It was in 1999.",
        "Did you get lost, {name}, or did the alarm fail for the 100th time?",
        "If punctuality was a crime, {name} would be the most innocent person alive.",
      ],
      'diet': [
        "Diet? {name} only does that between meals. 🍕",
        "Calories are practically chasing you down, {name}! 🍰",
        "Rest in peace, diet. We barely knew you. {name} just ate a pizza.",
        "You started on Monday, failed on Tuesday. Classic {name} behavior! 🍩",
        "One bite won't hurt... said {name} before eating the whole cake.",
      ],
      'relationship': [
        "Another relationship crisis, {name}? 🍿 Grab the popcorn!",
        "Single, taken, or just dramatically confused as usual, {name}? 💔",
        "Relationship status: It's extremely complicated with {name}.",
        "Drama Queen/King award goes to {name}! 👑",
        "Here we go again... standard soap opera starring {name}.",
      ],
      'custom': [
        "Classic {name} move.",
        "How many times is this now, {name}?",
        "Oh {name}... why are you like this? 🤦‍♂️",
        "The expected outcome has happened. No one is surprised.",
        "Congratulations {name}, you did it again! 🏆",
      ],
    }
  };

  static String getRoast(String category, String name, String lang) {
    final languageKey = lang.toLowerCase() == 'tr' ? 'tr' : 'en';
    final categoryKey = _roasts[languageKey]!.containsKey(category) ? category : 'custom';
    final list = _roasts[languageKey]![categoryKey]!;
    final template = list[_random.nextInt(list.length)];
    return template.replaceAll('{name}', name);
  }

  /// Asynchronously generates a personalized AI roast using Gemini with contextual fallback
  static Future<String> generateDynamicRoast({
    required String name,
    required String category,
    required String note,
    required String counterTitle,
    required String elapsedTime,
    String lang = 'tr',
  }) async {
    return GeminiService.generateRoast(
      name: name,
      category: category,
      note: note,
      counterTitle: counterTitle,
      elapsedTimeFormatted: elapsedTime,
      lang: lang,
    );
  }
}
