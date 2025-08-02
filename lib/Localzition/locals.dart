import 'package:flutter_localization/flutter_localization.dart';

const List<MapLocale> LOCALES = [
  MapLocale("en", LocaleData.EN),
  MapLocale("ru", LocaleData.RU),
  MapLocale("uz", LocaleData.UZ),
];

mixin LocaleData {
  static const String category = "category";
  static const String seorch = "seorch";
  static const String orders = "orders";
  static const String basket = "basket";
  static const String myprofile = "myprofile";
  static const String favorites = "favorites";
  static const String restaurants = "restaurants";
  static const String bonuses = "bonuses";
  static const String feedback = "feedback";
  static const String add = "add";
  static const String som = "som";
  static const String share = "share";
  static const String products = "products";
  static const String delivery = "delivery";
  static const String total = "total";
  static const String usebonus = "usebonus";
  static const String confirm = "confirm";
  static const String registration = "registration";
  static const String phonenumber = "phonenumber";
  static const String name = "name";
  static const String password = "password";
  static const String createaccount = "createaccount";
  static const String doyouhaveaccount = "doyouhaveaccount";
  static const String login = "login";
  static const String forgotyourpassword = "forgotyourpassword";
  static const String areyouherefirsttime = "areyouherefirsttime";
  static const String enterverificationcode = "enterverificationcode";
  static const String smssenttothesamephonenumber =
      "smssenttothesamephonenumber";
  static const String availablebonuses = "availablebonuses";
  static const String choosetheamount = "choosetheamount";
  static const String paymentmethods = "paymentmethods";
  static const String cash = "cash";
  static const String cardofdriver = "cardofdriver";
  static const String location = "location";
  static const String thankyouforchoosingus1 = "thankyouforchoosingus1";
  static const String thankyouforchoosingus2 = "thankyouforchoosingus2";
  static const String ordertime = "ordertime";
  static const String deliverytime = "deliverytime";
  static const String min = "min";
  static const String myaddresses = "myaddresses";
  static const String historyoforders = "historyoforders";
  static const String language = "language";
  static const String logout = "logout";
  static const String deleteaccount = "deleteaccount";
  static const String loginorregister = "loginorregister";
  static const String orderid = "orderid";
  static const String amount = "amonut";
  static const String weareonsocialnetworks = "weareonsocialnetworks";
  static const String ifyouhavesoapsorsuggestions =
      "ifyouhavesoapsorsuggestions";
  static const String sendamessagetotheemail = "sendamessagetotheemail";
  static const String edit = "edit";
  static const String delete = "delete";
  static const String track = "track";
  static const String orderconfirmed = "orderconfirmed";
  static const String preparing = "preparing";
  static const String giventodriver = "giventodriver";
  static const String delivered = "delivered";
  static const String pc = "pc";
  static const String menu = "Menu";
  static const String youdonnothaveaccount = "youdonnothaveaccount";
  static const String writeyourname = "writeyourname";
  static const String card = "card";
  static const String areyousureyouwanttocontinue =
      "areyousureyouwanttocontinue";
  static const String cancel = "cancel";
  static const String writecardname = "writecardname";
  static const String cardnumber = "cardnumber";
  static const String validityperiod = "validityperiod";
  static const String fillthecardinformation = "fillthecardinformation";
  static const String checkyourcard = "checkyourcard";
  static const String bonuslowercase = "bonuslowercase";
  static const String wrongphonenumber = "wrongphonenumber";
  static const String incorrectcode = "incorrectcode";
  static const String firstselectalocation = "firstselectalocation";
  static const String somethingwentwrong = "somethingwentwrong";
  static const String paymentwentsuccessful = "paymentwentsuccessful";
  static const String yourbasketisempty = "yourbasketisempty";
  static const String discount50 = "discount50";
  static const String whendownloadingtheapp = "whendownloadingtheapp";
  static const String deliverytime40 = "deliverytime40";
  static const String deliverytime15 = "deliverytime15";
  static const String therestaurantisclosed = "therestaurantisclosed";
  static const String indetail = "indetail";
  static const String takeaway = "takeaway";
  static const String accepted = "accepted";
  static const String inpreparation = "inpreparation";
  static const String ontheway = "ontheway";
  static const String confirorder = "confirorder";
  static const String chooselocation = "chooselocation";
  static const String birthdate = "birthdate";
  static const String selectYourBirthdate = "selectYourBirthdate";
  static const String gender = "gender";
  static const String selectYourGender = "selectYourGender";
  static const String done = "done";
  static const String addCommentsForLocation = "addCommentsForLocation";
  static const String enterComment = "enterComment";
  static const String writeYourCommentHere = "writeYourCommentHere";
  static const String submit = "submit";
  static const String feedbackForOrder = "feedbackForOrder";
  static const String writeYourFeedbackHere = "writeYourFeedbackHere";
  static const String type = "type";
  static const String ready = "ready";
  static const String sex = "sex";
  static const String cooldown = "cooldown";

  static const Map<String, dynamic> EN = {
    category: "Category",
    seorch: "Search",
    basket: "Basket",
    orders: "Orders",
    myprofile: "MY PROFILE",
    favorites: "FAVORITES",
    restaurants: "RESTAURANTS",
    bonuses: "BONUSES",
    feedback: "FEEDBACK",
    add: "Add",
    som: "som",
    share: "Share",
    products: "Products",
    delivery: "Delivery",
    total: "Total",
    usebonus: "Use bonus",
    confirm: "Confirm",
    registration: "Registration",
    phonenumber: "Phone number",
    name: "Name",
    password: "Password",
    createaccount: "Create account",
    doyouhaveaccount: "Do you have account ?",
    login: "Log in",
    forgotyourpassword: "Forgot your password?",
    areyouherefirsttime: "Are you here first time ?",
    enterverificationcode: "Enter verification code",
    smssenttothesamephonenumber: "Sms sent to the same phone number",
    availablebonuses: "Available bonuses:",
    choosetheamount: "Choose the amount:",
    paymentmethods: "Payment methods",
    cash: "Cash",
    cardofdriver: "Via card of driver",
    location: "Location",
    thankyouforchoosingus1: "Thank you",
    thankyouforchoosingus2: "for choosing us!",
    ordertime: "Order time",
    deliverytime: "Delivery time",
    min: "min",
    myaddresses: "My addresses",
    historyoforders: "History of orders",
    language: "language",
    logout: "Log out",
    deleteaccount: "Delete account",
    loginorregister: "Log in or register",
    orderid: "Order ID",
    amount: "Amount",
    weareonsocialnetworks: "We are on social networks",
    ifyouhavesoapsorsuggestions: "If you have soaps or suggestions",
    sendamessagetotheemail: "Send a message to the email",
    edit: "Edit",
    delete: "Delete",
    track: "Track",
    orderconfirmed: "Order confirmed",
    preparing: "Preparing",
    giventodriver: "Given to driver",
    delivered: "Delivered",
    pc: "PCs",
    menu: "Menu",
    youdonnothaveaccount: "You do not have an account",
    writeyourname: "Write your name",
    card: "Card",
    areyousureyouwanttocontinue: "Are you sure you want to continue?",
    cancel: "Cancel",
    writecardname: "Write card name",
    cardnumber: "Card number",
    validityperiod: "Validity period",
    fillthecardinformation: "Fill the card information",
    checkyourcard: "Check your card",
    bonuslowercase: "Bonuses",
    wrongphonenumber: "Wrong phone number",
    incorrectcode: "Incorrect code",
    firstselectalocation: "First, select a location",
    somethingwentwrong: "Something went wrong",
    paymentwentsuccessful: "Payment went Successful",
    yourbasketisempty: "Your basket is empty",
    discount50: " 50%\n Discount\n get it! 🎁",
    whendownloadingtheapp: "When downloading the app",
    deliverytime40: "from 40 min",
    deliverytime15: "from 15 min",
    therestaurantisclosed: "The restaurant is closed",
    indetail: "In detail",
    takeaway: "Take away",
    accepted: "Accepted",
    inpreparation: "In preparation",
    ontheway: "On the way",
    confirorder: "Confirm order",
    chooselocation: "Choose the location",
    birthdate: "Birthdate",
    selectYourBirthdate: "Select Your Birthdate",
    gender: "Gender",
    selectYourGender: "Select Your Gender",
    done: 'Done',
    addCommentsForLocation: "Add comments for location",
    enterComment: "Enter Comment",
    writeYourCommentHere: "Write your comment here..",
    submit: "Submit",
    feedbackForOrder: "Feedback for Order",
    writeYourFeedbackHere: "Write your feedback here...",
    type: "Type",
    ready: "Ready",
    sex: "Gender",
    cooldown: "Change limit reached",
  };

  static const Map<String, dynamic> RU = {
    category: "Категория",
    seorch: "Поиск",
    basket: "Корзина",
    orders: "Заказы",
    myprofile: "МОЙ ПРОФИЛЬ",
    favorites: "ИЗБРАННОЕ",
    restaurants: "РЕСТОРАНЫ",
    bonuses: "БОНУСЫ",
    feedback: "ОБРАТНАЯ СВЯЗЬ",
    add: "Добавить",
    som: "сум",
    share: "Поделиться",
    products: "Товары",
    delivery: "Доставка",
    total: "Итого",
    usebonus: "Воспользоваться бонусом",
    confirm: "Подтвердить",
    registration: "Регистрация",
    phonenumber: "Номер телефона",
    name: "Имя",
    password: "Пароль",
    createaccount: "Создать аккаунт",
    doyouhaveaccount: "Уже есть аккаунт?",
    login: "Войти",
    forgotyourpassword: "Забыл пароль?",
    areyouherefirsttime: "В первые у нас?",
    enterverificationcode: "Введите код подтверждения",
    smssenttothesamephonenumber: "Смс отправлен на номер",
    availablebonuses: "Имеющиеся бонусы:",
    choosetheamount: "Выбрать сумму:",
    paymentmethods: "Способ оплаты",
    cash: "Наличными",
    cardofdriver: "Картой курьеру",
    location: "Адрес",
    thankyouforchoosingus1: "Спасибо,",
    thankyouforchoosingus2: "что выбрали нас!",
    ordertime: "Время заказа",
    deliverytime: "Время доставка",
    min: "минут",
    myaddresses: "Мои адреса",
    historyoforders: "История заказов",
    language: "Изменить язык приложения",
    logout: "Выйти",
    deleteaccount: "Удалить аккаунт",
    loginorregister: "Войдите или зарегистрируйтесь",
    orderid: "ID заказа",
    amount: "Сумма",
    weareonsocialnetworks: "Мы в Социальных Сетях",
    ifyouhavesoapsorsuggestions: "Если у вас есть вопросы и/или предложения",
    sendamessagetotheemail: "Отправьте письмо на почту",
    edit: "Изменить",
    delete: "Удалить",
    track: "Отслеживание",
    orderconfirmed: "Принят",
    preparing: "Готовиться",
    giventodriver: "В пути",
    delivered: "Доставлен",
    pc: "шт",
    menu: "Меню",
    youdonnothaveaccount: "У вас нет учетной записи",
    writeyourname: "Напишите имя",
    card: "Карта",
    areyousureyouwanttocontinue: "Вы уверены, что хотите продолжить?",
    cancel: "Отмена",
    writecardname: "Напишите название карты",
    cardnumber: "Номер карты",
    validityperiod: "Срок годности",
    fillthecardinformation: "Заполните данные карты",
    checkyourcard: "Проверьте свою карту",
    bonuslowercase: "Бонусы",
    wrongphonenumber: "Неверный номер телефона",
    incorrectcode: "Неверный код",
    firstselectalocation: "Сначала выберите местоположение",
    somethingwentwrong: "Что-то пошло не так",
    paymentwentsuccessful: "Платеж прошел успешно",
    yourbasketisempty: "Ваша корзина пуста",
    discount50: " 50%\n Получите\n Скидки! 🎁",
    whendownloadingtheapp: "При загрузке приложения",
    deliverytime40: "от 40 мин",
    deliverytime15: "от 15 мин",
    therestaurantisclosed: "Ресторан закрыт",
    indetail: "Подробно",
    takeaway: "На вынос",
    accepted: "Принят",
    inpreparation: "Готовится",
    ontheway: "В пути",
    confirorder: "Подтвердить заказ",
    chooselocation: "Выберите место",
    birthdate: "Дата рождения",
    selectYourBirthdate: "Выберите вашу дату рождения",
    gender: "Пол",
    selectYourGender: "Выберите ваш пол",
    done: "Готово",
    addCommentsForLocation: "Добавить комментарии для местоположения",
    enterComment: "Введите комментарий",
    writeYourCommentHere: "Напишите ваш комментарий здесь...",
    submit: "Отправить",
    feedbackForOrder: "Отзыв о заказе",
    writeYourFeedbackHere: "Напишите ваш отзыв здесь...",
    type: "Тип",
    ready: "Готов",
    sex: "Пол",
    cooldown: "Лимит изменений достигнут"
  };

  static const Map<String, dynamic> UZ = {
    category: "Kategoriyalar",
    seorch: "Qidirmoq",
    basket: "Savatcha",
    orders: "Buyurtmalar",
    myprofile: "MENING PROFILIM",
    favorites: "TANLANGAN",
    restaurants: "RESTORANLAR",
    bonuses: "BONUSLAR",
    feedback: "Qayta aloqa",
    add: "Qo’shish",
    som: "so'm",
    share: "Ulashish",
    products: "Mahsulotlar",
    delivery: "Yetkazib berish",
    total: "Jami",
    usebonus: "Bonusdan foydalanish",
    confirm: "Tasdiqlash",
    registration: "Ro’yxatdan o’tish",
    phonenumber: "Telefon raqami",
    name: "Ismingis",
    password: "Parol",
    createaccount: "Akkaunt yaratish",
    doyouhaveaccount: "Akkauntingiz bormi ?",
    login: "Kirish",
    forgotyourpassword: "Parolni unutdingizmi?",
    areyouherefirsttime: "Bizda birinchi martamisiz?",
    enterverificationcode: "Tasdiqlash kodini kiriting",
    smssenttothesamephonenumber: "Sms shu telefon raqamga jo’natildi",
    availablebonuses: "Mavjud bonuslar:",
    choosetheamount: "Miqdorni tanlang:",
    paymentmethods: "To'lov usuli",
    cash: "Naqd pul",
    cardofdriver: "Haydovchi karta orqali",
    location: "Manzil",
    thankyouforchoosingus1: "Bizni,",
    thankyouforchoosingus2: "tanlaganingiz uchun rahmat!",
    ordertime: "Buyurtma vaqti",
    deliverytime: "Delivery time",
    min: "min",
    myaddresses: "Mening manzillarim",
    historyoforders: "Buyurtmalar tarixi",
    language: "Ilova tilini o'zgartirish",
    logout: "Chiqish",
    deleteaccount: "Akkaunti ochirish",
    loginorregister: "Tizimga kiring yoki ro'yxatdan o'ting",
    orderid: "Buyurtma ID",
    amount: "Miqdori",
    weareonsocialnetworks: "Biz ijtimoiy tarmoqlarda",
    ifyouhavesoapsorsuggestions: "Agar sizda sovollar yoki takliflar bo’lsa",
    sendamessagetotheemail: "Elektron pochtaga xabarni yuboring",
    edit: "O’zgartirish",
    delete: "O’chirish",
    track: "Kuzatuv",
    orderconfirmed: "Buyurtma tasdiqlandi",
    preparing: "Tayyorlanmoqda",
    giventodriver: "Yetkazib berish",
    delivered: "Yetkazib berildi",
    pc: "dona",
    menu: "Menyu",
    youdonnothaveaccount: "Sizda akkaunt yoq",
    writeyourname: "Ismingizni yozing",
    card: "Karta",
    areyousureyouwanttocontinue: "Davom etishni xohlaysizmi?",
    cancel: "Bekor qilish",
    writecardname: "Karta ismini yozing",
    cardnumber: "Karta raqami",
    validityperiod: "Yaroqlilik muddati",
    fillthecardinformation: "Karta ma'lumotlarini to'ldiring",
    checkyourcard: "Kartangizni tekshiring",
    bonuslowercase: "Bonuslar",
    wrongphonenumber: "Noto'g'ri telefon raqami",
    incorrectcode: "Noto'g'ri kod",
    firstselectalocation: "Avval joyni tanlang",
    somethingwentwrong: "Nimadir noto'g'ri bajarildi",
    paymentwentsuccessful: "Toʻlov muvaffaqiyatli oʻtdi",
    yourbasketisempty: "Savatingiz bo'sh",
    discount50: " 50%\n Chegirmani\n oling! 🎁",
    whendownloadingtheapp: "Ilovani yuklab olayotganda",
    deliverytime40: "40 min dan",
    deliverytime15: "15 min dan",
    therestaurantisclosed: "Restoran yopiq",
    indetail: "Tafsilotlar",
    takeaway: "Olib ketish",
    accepted: "Qabul qilingan",
    inpreparation: "Tayyorlanmoqda",
    ontheway: "Yo'lda",
    confirorder: "Zakazni tasdiqlash",
    chooselocation: "Joyni tanlang",
    birthdate: "Tug‘ilgan sana",
    selectYourBirthdate: "Tug‘ilgan sanani tanlang",
    gender: "Jins",
    selectYourGender: "Jinsni tanlang",
    done: "Tayyor",
    addCommentsForLocation: "Izohlar qo‘shish",
    enterComment: "Izoh kiriting",
    writeYourCommentHere: "Izohingizni bu yerga yozing...",
    submit: "Yuborish",
    feedbackForOrder: "Buyurtma uchun fidbek",
    writeYourFeedbackHere: "Fikringizni bu yerga yozing...",
    type: 'Turi',
    ready: 'Tayyor',
    sex: "Jins",
    cooldown: "O'zgartirish chegarasi yetdi",
  };
}
