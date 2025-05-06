import '../translation_keys.dart';

const Map<String, Map<String, String>> jaTranslations = {
  'intro': {
    // Intro Screen 1
    'title1': '部屋探しと管理の最高ツール！',
    'subtitle1': '賃貸物件の検索と管理を\nサポートするトップアプリ！',
    'buttonText1': 'ログイン',
    
    // Intro Screen 2
    'title2': 'スマートな部屋探し、\n適正価格！',
    'subtitle2': 'スマート検索技術で\nより良い選択をサポート！',
    'buttonText2': 'ログイン',
    
    // Intro Screen 3
    'title3': '管理と引越しの\n最高サポート！',
    'subtitle3': '部屋の管理システムと\nプロの運送会社との連携！',
    'buttonText3': '始める',
    
    // Common
    'skip': 'スキップ',
    'next': '次へ',
  },
  'home': {
    // Navigation
    'navHome': 'ホーム',
    'navExplore': '探索',
    'navFavorites': 'お気に入り',
    'navMessage': 'メッセージ',
    'navProfile': 'プロフィール',

    // Header
    'welcomeText': 'ようこそ',
    'searchHint': '部屋...',
    
    // Featured Section
    'featured': '特集',
    'seeAll': 'すべて見る',
    'perNight': '/泊',
    
    // Recommendation Section
    'ourRecommendation': 'おすすめ物件',
    
    // Filters
    'filterAll': '✅すべて',
    'filterHouse': '🏡一軒家',
    'filterVilla': '🏘 別荘',
    'filterApartment': '🏢アパート',

    // Property Details
    'rating': '評価',
    'night': '泊',
    'location': '場所',
  },
  'room_detail': {
    'overview': '概要',
    'facilities': '施設',
    'gallery': 'ギャラリー',
    'see_all': 'すべて見る',
    'read_more': '続きを読む',
    'show_less': '折りたたむ',
    'price': '料金',
    'per_night': '/泊',
    'contact_now': '連絡する',
    'owner': 'オーナー',
    'restaurant': 'レストラン',
    // Price Trends translations
    'price_trends': '価格推移',
    'price_trends_tooltip': '¥{0}',
    // Review section translations
    'reviews': 'レビュー',
    'days_ago': '{0}日前',
    'weeks_ago': '{0}週間前',
    'months_ago': '{0}ヶ月前',
    'likes': 'いいね {0}件',
    'rating_reviews': 'レビュー{0}件',
  },
  'verification': {
    'verification': '認証',
    'sentCodeToEmail': 'メールにコードを送信しました:',
    'onlyEnterNumbers': '数字のみを入力してください',
    'verify': '確認',
    'resendCode': 'コードを再送信',
    'or': 'または',
  },
  'auth': {
    // Sign In
    'signIn': 'ログイン',
    'email': 'メールアドレス',
    'password': 'パスワード',
    'rememberPassword': '記憶',
    'forgotPassword': '忘れた？',
    'loginWithGoogle': 'Googleでログイン',
    'loginWithFacebook': 'Facebookでログイン',
    'dontHaveAccount': 'アカウントをお持ちでないですか？ ',
    'or': 'または',
    
    // Sign Up
    'signUp': '新規登録',
    'fullName': '氏名',
    'confirmPassword': 'パスワード確認',
    'haveAccount': 'すでにアカウントをお持ちですか？ ',
  },
  'language': {
    'selectLanguage': '言語を選択',
    'languageDescription': 'お好みの言語を選択してください',
    'continueButton': '続ける',
    'vietnamese': 'Tiếng Việt',
    'english': 'English',
    'japanese': '日本語',
  },
  // Add more modules here: auth, settings, etc.
}; 