-- I DO NOT ADVISE YOU TRY TO EDIT BELOW THIS LINE UNLESS YOU UNDERSTAND HOW THIS WORKS!
-- IF YOU WANT TO ADD A LANAGUE PLEASE OPEN A SUPPORT TICKET ON GMODSTORE.
-- I WILL HELP YOU WITH ANYTHING YOU NEED AND ADD THE LANGUAGE TO THE OFFICIAL SCRIPT.
CH_ADVArrest.Config.Lang = CH_ADVArrest.Config.Lang or {}

-- Arresting/Handcuffing
CH_ADVArrest.Config.Lang["You've been arrested by"] = {
	["en"] = "You've been arrested by",
	["fr"] = "Vous avez été arrêté par",
	["da"] = "Du er blevet arresteret af",
	["de"] = "Du wurdest inhaftiert durch",
	["pl"] = "Zostałeś aresztowany przez",
	["ru"] = "Вас были арестованы",
	["es"] = "Has sido arrestado por",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklandınız. Sizi tutuklayan kişi",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You have been released from jail!"] = {
	["en"] = "You have been released from jail!",
	["fr"] = "Vous avez été libéré de prison!",
	["da"] = "Du er blevet løsladt fra fængslet!",
	["de"] = "Du wurdest aus dem Gefängnis entlassen!",
	["pl"] = "Zostałeś uwolniony z więzienia!",
	["ru"] = "Вас выпустили из тюрьмы!",
	["es"] = "¡Has sido liberado de la cárcel!",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Hapis cezan bitti ve hapisten çıkartıldın!",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You've handcuffed"] = { -- You've handcuffed player x
	["en"] = "You've handcuffed",
	["fr"] = "Vous êtes menotté",
	["da"] = "Du har lagt spilleren i håndjern",
	["de"] = "Du wurdest in Handschellen gelegt",
	["pl"] = "Jesteś zakuty.",
	["ru"] = "Вы надели наручники на",
	["es"] = "Has sido esposado",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kelepçelisin",
	["no"] = "",
}

-- Fallbacks
CH_ADVArrest.Config.Lang["The player is not close enough."] = {
	["en"] = "The player is not close enough.",
	["fr"] = "Le joueur n'est pas assez proche.",
	["da"] = "Personen er ikke tæt nok på.",
	["de"] = "Dieser Spieler ist nicht nah genug.",
	["pl"] = "Gracz nie jest wystarczająco blisko.",
	["ru"] = "Игрок недостаточно близко.",
	["es"] = "El jugador no está lo suficientemente cerca.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Oyuncu yeteri kadar yakın değil.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You need to be aiming at a player."] = {
	["en"] = "You need to be aiming at a player.",
	["fr"] = "Vous devez regarder un joueur.",
	["da"] = "Du skal sigte på en person.",
	["de"] = "Du musst den Spieler anvisieren.",
	["pl"] = "Musisz celować w gracza.",
	["ru"] = "Вы должны целиться в игрока.",
	["es"] = "Debes apuntar al jugador.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Bir oyuncuya bakman gerekmekte.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You cannot afford to pay your bail! You must serve all of your time in jail."] = {
	["en"] = "You cannot afford to pay your bail! You must serve all of your time in jail.",
	["fr"] = "Vous ne pouvez pas payer votre caution! Vous devez rester en prison pendant le temps donné.",
	["da"] = "Du har ikke råd til at betale din kaution! Du bliver nød til at afsone hele din straf i fængslet.",
	["de"] = "Du kannst dir deine Kaution nicht leisten. Du wirst deine Haftstrafe absitzen müssen!",
	["pl"] = "Nie stać cię na spłacenie kaucji! Musisz spędzić resztę swojego czasu w więzieniu.",
	["ru"] = "Вы не можете позволить внести залог за себя! Вы должны отбыть в тюрьме все время.",
	["es"] = "¡No puedes costear tu fianza! Deberás cumplir con la condena.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefaleti ödeyecek paran yok! Cezanı yatarak çekeceksin.",
	["no"] = "",
}

-- Player Inspection
CH_ADVArrest.Config.Lang["The inspecting police officer has confiscated your"] = {
	["en"] = "The inspecting police officer has confiscated your",
	["fr"] = "Un agent de police vous a confisqué vôtre",
	["da"] = "Politibetjenten har konfiskeret din",
	["de"] = "Der Polizist hat von dir beschlagnahmt: ",
	["pl"] = "Kontrolujący funkcjonariusz policji skonfiskował twoje",
	["ru"] = "Проверяющий полицейский конфисковал ваш",
	["es"] = "El oficial de policía que estaba inspeccionándote ha confiscado tu",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Seni inceleyen polis memuru şunlara el koydu",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["An officer is inspecting your belongings. Please do what the officer says to avoid any conflicts."] = {
	["en"] = "An officer is inspecting your belongings. Please do what the officer says to avoid any conflicts.",
	["fr"] = "Un agent de police inspecte vos affaires. Veuillez faire ce que l'agent vous dit pour éviter tout problèmes.",
	["da"] = "En politibetjent undersøger dine egendele. Gør venligst som der bliver sagt for at undgå en konflikt.",
	["de"] = "Du wirst von einem Polizisten durchsucht. Folge seinen Anweisungen, um Konflikte zu vermeiden.",
	["pl"] = "Funkcjonariusz Policji sprawdza twoje rzeczy. Proszę słuchać się jego poleceń aby uniknąć konfliktu.",
	["ru"] = "Офицер осматривает ваши вещи. Пожалуйста, делайте то, что говорит офицер, чтобы избежать конфликтов.",
	["es"] = "Un oficial está inspeccionando tus pertenencias. Por favor, haz lo que el oficial diga para evadir conflictos.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Bir polis memuru eşyalarınıza göz atıyor. Lütfen polisin dediği her şeyi yapın ve olay çıkartmayın.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You need to handcuff the player before you can inspect them."] = {
	["en"] = "You need to handcuff the player before you can inspect them.",
	["fr"] = "Vous devez menotter le joueur avant de pouvoir inspecter ses affaires.",
	["da"] = "Du er nød til at sætte personen i håndjern før du kan undersøge deres egendele.",
	["de"] = "Du musst dem Spieler Handschellen anlegen, um ihn durchsuchen zu können.",
	["pl"] = "Musisz zakuć gracza zanim go przeszukasz",
	["ru"] = "Вам необходимо надеть на игрока наручники, прежде чем вы сможете его осмотреть.",
	["es"] = "Debes esposar al jugador antes de poder inspeccionarlo.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Birini incelemek için ilk başta kelepçelemelisin.",
	["no"] = "",
}

-- Paying bail
CH_ADVArrest.Config.Lang["has paid their bail of"] = { -- x player has paid their bail of $xxx
	["en"] = "has paid their bail of",
	["fr"] = "a payé sa caution de",
	["da"] = "har betalt sin kaution på",
	["de"] = "hat deine Kaution bezahlt in Höhe von",
	["pl"] = "wpłacił kaucje",
	["ru"] = "заплатил залог в",
	["es"] = "ha pagado su fianza de",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "şu oyuncunun kefaletini ödedi",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["The money has been added to your wallet."] = {
	["en"] = "The money has been added to your wallet.",
	["fr"] = "L'argent a été ajouté à votre porte-monnaie.",
	["da"] = "Pengene er blevet tilføjet til din pung.",
	["de"] = "Das Geld wurde deiner Brieftasche hinzugefügt.",
	["pl"] = "Pieniądze zostały dodane do twojego portfela",
	["ru"] = "Деньги добавлены в ваш кошелек.",
	["es"] = "El dinero fue añadido a tu billetera.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Para cüzdanına eklendi.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["The money has been added to the mayors wallet."] = {
	["en"] = "The money has been added to the mayors wallet.",
	["fr"] = "L'argent a été ajouté au porte-monnaie du maire.",
	["da"] = "Pengene er blevet tilføjet til borgmesterens pung.",
	["de"] = "Das Geld wurde dem Bürgermeister übergeben.",
	["pl"] = "Pieniądze zostały dodane do portfela burmistrza",
	["ru"] = "Деньги добавлены в кошелек мэра.",
	["es"] = "El dinero fue añadido a la billetera del Presidente.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Para başkanın cüzdanına eklendi.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["The money has been destroyed."] = {
	["en"] = "The money has been destroyed.",
	["fr"] = "L'argent a été détruit.",
	["da"] = "Pengene er blevet destrueret.",
	["de"] = "Das Geld wurde vernichtet.",
	["pl"] = "Pieniądze uległy zniszczeniu",
	["ru"] = "Деньги были уничтожены.",
	["es"] = "El dinero ha sido destruído.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Para yok edildi.",
	["no"] = "",
}

-- Handcuffs
CH_ADVArrest.Config.Lang["Left click to arrest or unarrest a handcuffed target.\nRight click to handcuff your target.\nReload to open player inspection menu."] = {
	["en"] = "Left click to arrest or unarrest a handcuffed target.\nRight click to handcuff your target.\nReload to open player inspection menu.",
	["fr"] = "Click gauche pour arrêter ou libérer la personne menotté que vous regardez.\nClick droit pour menotter la personne que vous regardez.\nRechargez pour ouvrir le menu d'inspection.",
	["da"] = "Venstre click for at arrestere eller løslade målet. Højre click for at sætte målet i håndjern. Reload for at inspicere målets egendele.",
	["de"] = "Klicke mit der linken Maustaste, um ein mit Handschellen gefesseltes Ziel zu verhaften oder freizulassen. \nLade nach, um den Spieler zu durchsuchen.",
	["pl"] = "Lewy przycisk aby zaaresztować lub uwolnić z więzienia zakutego gracza.\nPrawy przycisk aby zakuć gracza.\nPrzeładowanie aby otworzyć menu przeszukania gracza.",
	["ru"] = "Нажмите левую кнопку мыши, чтобы арестовать или освободить цель в наручниках.\n Нажмите правую кнопку мыши, чтобы надеть на цель наручники.\nПерезарядка, чтобы открыть меню осмотра игрока.",
	["es"] = "Click izquierdo para arrestar o liberar a un jugador.\nClick derecho para esposar a tu objetivo.\nR (Reload) para abrir el menú de inspección de jugador.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kelepçeli kişiyi sol tık ile tutukla veya tutuklama. \nSağ tık ile hedefini kelepçele. \nYeniden doldurarak inceleme menüsünü aç.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Used to arrest, unarrest, handcuff and inspect players."] = {
	["en"] = "Used to arrest, unarrest, handcuff and inspect players.",
	["fr"] = "Utilisé pour arrêter, libérer, menotter et inspecter un joueur.",
	["da"] = "Brug til at arrestere, løslade, sætte i håndjern eller inspicere målets egendele.",
	["de"] = "Wird benutzt, um einen Spieler zu inhaftieren, freizulassen, Handschellen anzulegen oder zu durchsuchen.",
	["pl"] = "Używane do aresztowania, uwalniania z więzienia, zakuwania i przeszukiwania graczy.",
	["ru"] = "Используется для ареста, задержания, надевания наручников и досмотра игроков.",
	["es"] = "Usado para arrestar, liberar, esposar e inspeccionar jugadores.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklamaya, salmaya ve incelemeye yarar.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You are being arrested. Please do what the officer says to avoid any conflicts."] = {
	["en"] = "You are being arrested. Please do what the officer says to avoid any conflicts.",
	["fr"] = "Vous êtes en train d'être arrêté. Veuillez faire ce que dit l'agent pour éviter tout problèmes.",
	["da"] = "Du bliver arresteret. Gør venligst som der bliver sagt for at undgå en konflikt.",
	["de"] = "Du wirst verhaftet. Folge den Anweisungen des Polizisten, um Konflikte zu vermeiden.",
	["pl"] = "Zostajesz aresztowany. Proszę wykonywać polecenia aby uniknąć problemów.",
	["ru"] = "Вас арестовывают. Пожалуйста, делайте то, что говорит офицер, чтобы избежать конфликтов.",
	["es"] = "Estás siendo arrestado. Por favor, haz lo que el oficial te diga para evitar conflictos.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklanıyorsun. Lütfen polis memurunu dinleyin ve olay çıkarmayın.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You need to handcuff the player before you can arrest them."] = {
	["en"] = "You need to handcuff the player before you can arrest them.",
	["fr"] = "Vous devez menotter le joueur avant de pouvoir l'arrêter.",
	["da"] = "Du er nød til at placere håndjern på personen før du kan arrestere dem.",
	["de"] = "Du musst einem Spieler Handschellen anlegen, um ihn verhaften zu können.",
	["pl"] = "Musisz zakuć gracza zanim zostanie aresztowany.",
	["ru"] = "Вам нужно надеть на игрока наручники, прежде чем вы сможете его арестовать.",
	["es"] = "Debes esposar al jugador antes de poder arrestarlo.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Birini tutuklamak için ilk başta onu kelepçelemelisiniz.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["is arrested. Left click to unarrest them!"] = { -- x player is arrested. Left click to unarrest them!
	["en"] = "is arrested. Left click to unarrest them!",
	["fr"] = "est arrêté. Click gauche de la souris pour les libérer!",
	["da"] = "er arresteret. Venstre klik for at løslade dem!",
	["de"] = "ist inhaftiert. Linksklick um ihn freizulassen!",
	["pl"] = "jest zaaresztowany. Lewy przycisk aby go uwolnić z więzienia!",
	["ru"] = "арестован. Нажмите левую кнопку мыши, чтобы снять арест!",
	["es"] = "está arrestado ¡Click izquerido para liberarlo!",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "tutuklandı. Sıl tık ile onu salabilirsin!",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["has been released from their handcuffs."] = { -- x player has been released from their handcuffs.
	["en"] = "has been released from their handcuffs.",
	["fr"] = "a été libéré de ses menottes.",
	["da"] = "er blevet løsladt fra sine håndjern.",
	["de"] = "wurde aus seinen Handschellen befreit.",
	["pl"] = "Został uwolniony z kajdanek",
	["ru"] = "был освобожден от наручников.",
	["es"] = "ha sido liberado de sus esposas.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "kelepçelerinden kurtuldu",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Hand-Cuffing"] = { -- for handcuff loading bar (when giving handcuffing a player)
	["en"] = "Hand-Cuffing",
	["fr"] = "Menottage",
	["da"] = "Sætter i håndjern",
	["de"] = "Lege Handschellen an...",
	["pl"] = "Zakuwanie",
	["ru"] = "Задержание",
	["es"] = "Esposando",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kelepçeleme",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Player Handcuffed"] = {
	["en"] = "Player Handcuffed",
	["fr"] = "Joueur menotté",
	["da"] = "Spiller I Håndjern",
	["de"] = "Spieler in Handschellen",
	["pl"] = "Gracz zakuty",
	["ru"] = "Игрок в Наручниках",
	["es"] = "Jugador Esposado",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Oyuncu Kelepçelendi",
	["no"] = "",
}

-- Police Baton
CH_ADVArrest.Config.Lang["Left Click: Hit using the baton"] = {
	["en"] = "Left Click: Hit using the baton",
	["fr"] = "Click Gauche: Frapper avec le bâton",
	["da"] = "Venstre klik: Slå med staven.",
	["de"] = "Linksklick: Mit dem Schlagstock schlagen",
	["pl"] = "Lewy przycisk: uderz aby użyć pałki",
	["ru"] = "Левая кнопка: Ударить применяя дубинку",
	["es"] = "Click izquierdo: Golpea usando la porra",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Sol Tık: Job ile vur",
	["no"] = "",
}

-- Menus
CH_ADVArrest.Config.Lang["Arresting Menu"] = {
	["en"] = "Arresting Menu",
	["fr"] = "Menu d'arrestations",
	["da"] = "Arrestere Menu",
	["de"] = "Inhaftierungsmenü",
	["pl"] = "Menu Aresztowania",
	["ru"] = "Меню ареста",
	["es"] = "Menú de Arresto",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklama Menüsü",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Choose Arrest Time"] = {
	["en"] = "Choose Arrest Time",
	["fr"] = "Choisissez le temps de l'arrestation",
	["da"] = "Vælg Fængsels Tid",
	["de"] = "Wähle die Haftzeit",
	["pl"] = "Wybierz Czas Aresztu",
	["ru"] = "Выберите время ареста",
	["es"] = "Elegir el tiempo de arresto",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklama Süresini Seç",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Choose Bail Price"] = {
	["en"] = "Choose Bail Price",
	["fr"] = "Choisissez le prix de la caution",
	["da"] = "Vælg Kautions Pris",
	["de"] = "Wähle Kautionspreis",
	["pl"] = "Wybierz Cenę Kaucji",
	["ru"] = "Выберите цену залога",
	["es"] = "Elegir precio de fianza",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefalet Ücretini Seç",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Bail:"] = { -- Bail: $xxx
	["en"] = "Bail:",
	["fr"] = "Caution:",
	["da"] = "Kaution:",
	["de"] = "Kaution:",
	["pl"] = "Kaucja:",
	["ru"] = "Залог:",
	["es"] = "Fianza:",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefalet Öde:",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["No Bail"] = {
	["en"] = "No Bail",
	["fr"] = "Pas de Caution",
	["da"] = "Ingen Kaution",
	["de"] = "Keine Kaution",
	["pl"] = "Bez Kaucji",
	["ru"] = "Без Залога",
	["es"] = "Sin Fianza",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefalet Bulunmamakta",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Arrest Player"] = {
	["en"] = "Arrest Player",
	["fr"] = "Arrêter le Joueur",
	["da"] = "Arrester Spiller",
	["de"] = "Spieler inhaftieren",
	["pl"] = "Zaaresztuj Gracza",
	["ru"] = "Арестовать игрока",
	["es"] = "Arrestar jugador",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Oyuncuyu Tutukla",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Cancel Arrest"] = {
	["en"] = "Cancel Arrest",
	["fr"] = "Annuler l'Arrestation",
	["da"] = "Forlad",
	["de"] = "Inhaftierung abbrechen",
	["pl"] = "Anuluj Aresztowanie",
	["ru"] = "Отменить арест",
	["es"] = "Cancelar arresto",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklamayı İptal Et",
	["no"] = "",
}

-- Bail Menu
CH_ADVArrest.Config.Lang["Bail Options"] = {
	["en"] = "Bail Options",
	["fr"] = "Options de la Caution",
	["da"] = "Kautions Muligheder",
	["de"] = "Kautionsoptionen",
	["pl"] = "Opcje Kaucji",
	["ru"] = "Варианты Залога",
	["es"] = "Opciones de Fianza",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefalet Ayarları",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You have been arrested!"] = {
	["en"] = "You have been arrested!",
	["fr"] = "Vous avez été arrêté !",
	["da"] = "Du er blevet arresteret!",
	["de"] = "Du wurdest inhaftiert.",
	["pl"] = "Zostałeś aresztowany!",
	["ru"] = "Вы были арестованы!",
	["es"] = "¡Has sido arrestado!",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklandın!",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Bail Price:"] = { -- Bail Price: $xxx
	["en"] = "Bail Price:",
	["fr"] = "Prix de la Caution:",
	["da"] = "Kautions Pris:",
	["de"] = "Kautionspreis:",
	["pl"] = "Cena Kaucji:",
	["ru"] = "Цена залога:",
	["es"] = "Precio de Fianza:",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefalet Ücreti:",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Pay Bail"] = {
	["en"] = "Pay Bail",
	["fr"] = "Payer la Caution",
	["da"] = "Betalt Kaution",
	["de"] = "Zahle Kaution",
	["pl"] = "Zapłać Kaucje",
	["ru"] = "Внести залог",
	["es"] = "Pagar Fianza",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefaleti Öde",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Decline Bail"] = {
	["en"] = "Decline Bail",
	["fr"] = "Décliner la Caution",
	["da"] = "Modsig Kaution",
	["de"] = "Lehne Kaution ab",
	["pl"] = "Anuluj Kaucje",
	["ru"] = "Отклонить залог",
	["es"] = "Denegar Fianza",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Kefaleti Reddet",
	["no"] = "",
}

-- Player Inspection Menu
CH_ADVArrest.Config.Lang["Inspecting Player"] = {
	["en"] = "Inspecting Player",
	["fr"] = "Inspection du Joueur",
	["da"] = "Inspicer Person",
	["de"] = "Durchsuche Spieler",
	["pl"] = "Przeszukiwanie Gracza",
	["ru"] = "Осмотр Игрока",
	["es"] = "Inspeccionando Jugador",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Oyuncu İnceleniyor",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Name"] = {
	["en"] = "Name",
	["fr"] = "Nom",
	["da"] = "Navn",
	["de"] = "Name",
	["pl"] = "Nazwa",
	["ru"] = "Имя",
	["es"] = "Nombre",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "İsim",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Job"] = {
	["en"] = "Job",
	["fr"] = "Métier",
	["da"] = "Job",
	["de"] = "Beruf",
	["pl"] = "Praca",
	["ru"] = "Работа",
	["es"] = "Trabajo",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Meslek",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Wallet"] = {
	["en"] = "Wallet",
	["fr"] = "Porte-monnaie",
	["da"] = "Pung",
	["de"] = "Brieftasche",
	["pl"] = "Portfel",
	["ru"] = "Бумажник",
	["es"] = "Billetera",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Cüzdan",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Confiscate"] = {
	["en"] = "Confiscate",
	["fr"] = "Confisquer",
	["da"] = "Konfisker",
	["de"] = "Beschlagnahmen",
	["pl"] = "Konfiskacja",
	["ru"] = "Конфисковать",
	["es"] = "Confiscar",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "El Koy",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Finish Inspection"] = {
	["en"] = "Finish Inspection",
	["fr"] = "Finir l'Inspection",
	["da"] = "Færdigør Inspektion",
	["de"] = "Beende Durchsuchung",
	["pl"] = "Przeszukanie zakończone",
	["ru"] = "Завершить Осмотр",
	["es"] = "Terminar Inspección",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "İncelemeyi Bitir",
	["no"] = "",
}

-- Jailer NPC
CH_ADVArrest.Config.Lang["You must bring the criminal to the jailer NPC in order to arrest them!"] = {
	["en"] = "You must bring the criminal to the jailer NPC in order to arrest them!",
	["fr"] = "Vous devez amener le criminel au PNJ geôlier afin de l'arrêter!",
	["da"] = "Du skal bringe den kriminelle til fange NPCen for at arrestere dem!",
	["de"] = "Du musst den Gefangenen zum NPC bringen, um ihn zu verhaften!",
	["pl"] = "Musisz przynieść przestępce do strażnika więziennego (NPC), aby go zaaresztować!",
	["ru"] = "Вы должны привести преступника к NPC-тюремщику, чтобы арестовать его!",
	["es"] = "¡Debes llevar al criminal al carcelero NPC para arrestarlo!",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Birini tutuklamak için suçluyu gardiyan NPC'sine götürmek gerekmekte!",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["New position for the jailer NPC has been succesfully set."] = {
	["en"] = "New position for the jailer NPC has been succesfully set.",
	["fr"] = "Un nouveau poste pour le PNJ geôlier a été défini avec succès.",
	["da"] = "Ny position for fange NPC er blevet sat.",
	["de"] = "Es wurde eine neue Position für den Inhaftierungs-NPC gesetzt.",
	["pl"] = "Nowa pozycja dla strażnika więziennego (NPC) została pomyślnie ustawiona.",
	["ru"] = "Успешно установлена ​​новая позиция для NPC-тюремщика.",
	["es"] = "Se ha establecido con éxito una nueva posición para el carcelero NPC.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Gardiyan NPC'nin pozisyonu başarıyla ayarlandı.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["The NPC will respawn in 5 seconds. Move out the way."] = {
	["en"] = "The NPC will respawn in 5 seconds. Move out the way.",
	["fr"] = "Le PNJ va rйapparaоtre dans 5 secondes. Veuillez vous йloigner.",
	["da"] = "NPC'en spawner om 5 sekunder. Flyt dig til siden.",
	["de"] = "Der NPC wird in 5 Sekunden wieder erscheinen. Bitte geh zur Seite.",
	["pl"] = "NPC zostanie zrespiony za 5 sekund, zejdź z miejsca respu.",
	["ru"] = "NPC возродится через 5 секунд. Освободите дорогу.",
	["es"] = "El NPC reaparecerá en 5 segundos. Muévete del lugar.",
	["pt"] = "",
	["cn"] = "NPC会在5秒后重现。",
	["tr"] = "NPC 5 saniye sonra canlanicak. Yoldan cekil.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["The jailer NPC has been respawned."] = {
	["en"] = "The jailer NPC has been respawned.",
	["fr"] = "Le PNJ geôlier a été réapparu.",
	["da"] = "Fængsleren NPC er blevet respawnet.",
	["de"] = "Der Inhaftierungs-NPC wurde respawned.",
	["pl"] = "Strażnik więziennny (NPC) został zrespiony.",
	["ru"] = "NPC-тюремщик возродился.",
	["es"] = "La PNJ carcelera ha sido reaparecida.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Gardiyan NPC'si yeniden doğdu.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Only administrators can perform this action!"] = {
	["en"] = "Only administrators can perform this action!",
	["fr"] = "Seuls les administrateurs peuvent exйcuter cette action!",
	["da"] = "Kun administratorer kan udføre denne handling!",
	["de"] = "Nur die Administratoren können diese Aktion ausführen!",
	["pl"] = "Tylko administratorzy mogą to zrobić!",
	["ru"] = "Только администраторы могут выполнить это действие!",
	["es"] = "¡Sólo los administradores pueden ejecutar esta acción!",
	["pt"] = "",
	["cn"] = "只有管理员才能执行这个操作!",
	["tr"] = "Sadece yetkililer bu eylemi gerceklestirebilir.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["There is no handcuffed player nearby. Please bring them closer to the NPC."] = {
	["en"] = "There is no handcuffed player nearby. Please bring them closer to the NPC.",
	["fr"] = "Il n'y a pas de joueur menotté à proximité. Veuillez les rapprocher du PNJ.",
	["da"] = "Der er ingen spiller i håndjern i nærheden. Bring dem nærmere NPCen.",
	["de"] = "Es befindet sich kein Spieler in Handschellen im näheren Umfeld. Bitte bring ihn näher zum NPC.",
	["pl"] = "Nie ma żadnego zakutego gracza w pobliżu. Proszę go przyprowadzić bliżej NPC.",
	["ru"] = "Рядом нет игрока в наручниках. Пожалуйста, поднесите их поближе к NPC.",
	["es"] = "No hay ningún jugador esposado cerca. Por favor, acérquelos al NPC.",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Yakın çevrede kelepçeli bir oyuncu bulunmamakta. Lütfen onu NPC'ye yaklaştırın.",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["You are about to arrest"] = {
	["en"] = "You are about to arrest",
	["fr"] = "Vous êtes sur le point d'arrêter",
	["da"] = "Du er ved at anholde",
	["de"] = "Du bist dabei jemanden inhaftieren.",
	["pl"] = "Masz zamiar aresztować",
	["ru"] = "Вы собираетесь арестовать",
	["es"] = "Estás a punto de arrestar",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Tutuklamak üzeresin",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Jailer"] = {
	["en"] = "Jailer",
	["fr"] = "Geôlier",
	["da"] = "Fangevogter",
	["de"] = "Gefängniswärter",
	["pl"] = "Strażnik więzienny",
	["ru"] = "тюремщик",
	["es"] = "Carcelero",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "gardiyan",
	["no"] = "",
}

CH_ADVArrest.Config.Lang["Bring criminals here to arrest them"] = {
	["en"] = "Bring criminals here to arrest them",
	["fr"] = "Amenez des criminels ici pour les arrêter",
	["da"] = "Bring kriminelle hertil for at arrestere dem",
	["de"] = "Bringen Sie Kriminelle hierher, um sie zu verhaften",
	["pl"] = "Przyprowadź tu przestępców, żeby ich aresztowali",
	["ru"] = "Приведите сюда преступников, чтобы арестовать их.",
	["es"] = "Trae criminales aquí para arrestarlos",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "Suçluları tutuklamak için buraya getirin",
	["no"] = "",
}

--[[
CH_ADVArrest.Config.Lang[""] = {
	["en"] = "",
	["fr"] = "",
	["da"] = "",
	["de"] = "",
	["pl"] = "",
	["ru"] = "",
	["es"] = "",
	["pt"] = "",
	["cn"] = "",
	["tr"] = "",
	["no"] = "",
}
--]]