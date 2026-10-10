class AppLocalizations {
  static const Map<String, String> _tr = {
    // App Header & Tabs
    'appTitle': 'Sıfırlandı!',
    'tabPersonal': 'Bireysel',
    'tabShared': 'Ortak',
    'tabExplore': '🌍 Keşfet',
    'profilesHeader': 'SAYAÇLAR',
    'sharedHeader': 'ORTAK SAYAÇLAR',
    'emptyProfiles': 'Henüz sayaç eklenmedi.',
    'emptyProfilesSub': '+ butonuna basarak ilk sayacını oluştur!',
    'emptyShared': 'Ortak sayaç bulunamadı.',
    'emptySharedSub': 'Arkadaşının oda kodunu girerek dahil ol!',

    // Common Buttons
    'save': 'Kaydet',
    'cancel': 'Vazgeç',
    'delete': 'Sil',
    'close': 'Kapat',
    'share': 'Paylaş',
    'copy': 'Kopyala',
    'join': 'Katıl',
    'resetBtn': 'SIFIRLA',

    // Add Profile Dialog
    'createTitle': 'Yeni Sayaç Oluştur',
    'personName': 'Kişi / Hedef Adı',
    'counterName': 'Sayaç Başlığı',
    'selectCategory': 'Kategori Seç',
    'isSharedCounter': 'Ortak (Multiplayer) Sayaç Yap',
    'isSharedSub': 'Arkadaşlarınla WhatsApp üzerinden ortak takip et',
    'createBtn': 'Sayaç Oluştur',

    // Stats & Details
    'daysWithoutIncident': 'GÜNDÜR SIFIRLANMADI',
    'totalResets': 'Toplam Sıfırlama',
    'frequency': 'Ortalama Sıklık',
    'longestStreak': 'En Uzun Seri',
    'recentResets': 'Son Sıfırlanmalar',
    'noResetsYet': 'Henüz sıfırlanma kaydı yok. Kusursuz gidiyor! 🚀',
    'days': 'Gün',
    'hours': 'Saat',
    'minutes': 'Dakika',
    'seconds': 'Saniye',

    // Reset Flow
    'resetTitle': 'Sayacı Sıfırla',
    'resetReasonHint': 'Ne oldu da sıfırlandı? (Örn: Gece 3 te çiğ köfte yedim)',
    'resetConfirm': 'SIFIRLA VE LAF SOK 💥',
    'roastClose': 'Utancı Kabul Et 🫡',

    // Deletion
    'deleteTitle': 'Kaydı Sil',
    'deleteDesc': 'Bu sıfırlanma kaydını silmek istediğinize emin misiniz?',
    'deleteProfileTitle': 'Sayacı Tamamen Sil?',
    'deleteProfileDesc': 'Bu sayacı ve tüm geçmişini silmek istediğinize emin misiniz? Bu işlem geri alınamaz!',

    // Milestones & Gamification
    'milestones': 'BAŞARI ROZETLERİ',
    'penaltyWheel': 'Ceza Çarkı 🎯',
    'groupCourt': 'Mahkeme ⚖️',
    'widgetStudio': 'Widget Stüdyosu 🧩',

    // Room / Invites
    'roomCode': 'ODA KODU',
    'inviteFriends': 'Arkadaşlarını Çağır',
    'shareWhatsapp': 'WhatsApp\'ta Davet Et',
    'copyLink': 'Linki Kopyala',
  };

  static const Map<String, String> _en = {
    // App Header & Tabs
    'appTitle': 'Reseted!',
    'tabPersonal': 'Personal',
    'tabShared': 'Shared',
    'tabExplore': '🌍 Explore',
    'profilesHeader': 'COUNTERS',
    'sharedHeader': 'SHARED COUNTERS',
    'emptyProfiles': 'No counters added yet.',
    'emptyProfilesSub': 'Tap the + button to create your first counter!',
    'emptyShared': 'No shared rooms found.',
    'emptySharedSub': 'Enter a friend\'s room code to join!',

    // Common Buttons
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'close': 'Close',
    'share': 'Share',
    'copy': 'Copy',
    'join': 'Join',
    'resetBtn': 'RESET',

    // Add Profile Dialog
    'createTitle': 'Create New Counter',
    'personName': 'Person / Target Name',
    'counterName': 'Counter Title',
    'selectCategory': 'Select Category',
    'isSharedCounter': 'Make Shared (Multiplayer)',
    'isSharedSub': 'Track together with friends via WhatsApp invite',
    'createBtn': 'Create Counter',

    // Stats & Details
    'daysWithoutIncident': 'DAYS WITHOUT INCIDENT',
    'totalResets': 'Total Resets',
    'frequency': 'Average Frequency',
    'longestStreak': 'Longest Streak',
    'recentResets': 'Recent Resets',
    'noResetsYet': 'No resets recorded yet. Streak is flawless! 🚀',
    'days': 'Days',
    'hours': 'Hours',
    'minutes': 'Minutes',
    'seconds': 'Seconds',

    // Reset Flow
    'resetTitle': 'Reset Counter',
    'resetReasonHint': 'What happened? (e.g. Ate pizza at 3 AM)',
    'resetConfirm': 'RESET AND ROAST 💥',
    'roastClose': 'Accept the Shame 🫡',

    // Deletion
    'deleteTitle': 'Delete Entry',
    'deleteDesc': 'Are you sure you want to delete this reset record?',
    'deleteProfileTitle': 'Delete Counter Permanently?',
    'deleteProfileDesc': 'Are you sure you want to delete this counter and its history? This action cannot be undone!',

    // Milestones & Gamification
    'milestones': 'MILESTONE BADGES',
    'penaltyWheel': 'Penalty Wheel 🎯',
    'groupCourt': 'Group Court ⚖️',
    'widgetStudio': 'Widget Studio 🧩',

    // Room / Invites
    'roomCode': 'ROOM CODE',
    'inviteFriends': 'Invite Friends',
    'shareWhatsapp': 'Share on WhatsApp',
    'copyLink': 'Copy Link',
  };

  /// Returns localized string by key and language code ('tr' or 'en')
  static String tr(String key, {String lang = 'tr'}) {
    final dict = lang == 'en' ? _en : _tr;
    return dict[key] ?? _tr[key] ?? key;
  }
}
