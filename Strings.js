.pragma library

// UI strings. "auto" follows the system language (LC_ALL, LC_MESSAGES, LANG)
// and falls back to English for languages without a dictionary.

var dictionaries = {
  en: {
    title: "Window Layout",
    window: "Window: %1",
    noWindow: "No window selected",
    status: "Workspace %1 · %2 · %3 layout",
    sectionWindow: "WINDOW",
    sectionSplit: "SPLIT",
    sectionMove: "MOVE WINDOW",
    sectionWorkspace: "WORKSPACE",
    sectionDisplays: "DISPLAYS",
    fullscreen: "Fullscreen",
    maximize: "Maximize",
    float: "Float",
    pin: "Pin",
    close: "Close",
    toggleSplit: "Toggle split",
    swapSides: "Swap sides",
    ratioHint: "Left or top | right or bottom",
    arrowsHint: "Arrows: swap with neighbor",
    numbersHint: "Numbers: send to workspace",
    toDisplay: "To display:",
    layout: "Layout: %1",
    gaps: "Gaps",
    workspaceToDisplay: "Move workspace to:",
    laptopDisplay: "Laptop display",
    mirrorLaptop: "Mirror laptop",
    laptop: "Laptop",
    errStatus: "Couldn't read the window state",
    errWindowGone: "That window no longer exists",
    errInvalid: "Invalid request",
    errRefused: "Hyprland refused the action",
    errFailed: "Something went wrong"
  },
  pt: {
    title: "Organizar janelas",
    window: "Janela: %1",
    noWindow: "Nenhuma janela selecionada",
    status: "Workspace %1 · %2 · layout %3",
    sectionWindow: "JANELA",
    sectionSplit: "DIVISÃO",
    sectionMove: "MOVER JANELA",
    sectionWorkspace: "WORKSPACE",
    sectionDisplays: "MONITORES",
    fullscreen: "Tela cheia",
    maximize: "Maximizar",
    float: "Flutuar",
    pin: "Destacar",
    close: "Fechar",
    toggleSplit: "Alternar divisão",
    swapSides: "Inverter lados",
    ratioHint: "Esquerda ou cima | direita ou baixo",
    arrowsHint: "Setas: troca com a vizinha",
    numbersHint: "Números: manda para o workspace",
    toDisplay: "Para o monitor:",
    layout: "Layout: %1",
    gaps: "Margens",
    workspaceToDisplay: "Levar o workspace para:",
    laptopDisplay: "Tela do notebook",
    mirrorLaptop: "Espelhar notebook",
    laptop: "Notebook",
    errStatus: "Não consegui ler o estado das janelas",
    errWindowGone: "Essa janela não existe mais",
    errInvalid: "Pedido inválido",
    errRefused: "O Hyprland recusou a ação",
    errFailed: "Algo deu errado"
  },
  sv: {
    title: "Fönsterlayout",
    window: "Fönster: %1",
    noWindow: "Inget fönster valt",
    status: "Arbetsyta %1 · %2 · layout %3",
    sectionWindow: "FÖNSTER",
    sectionSplit: "DELNING",
    sectionMove: "FLYTTA FÖNSTER",
    sectionWorkspace: "ARBETSYTA",
    sectionDisplays: "SKÄRMAR",
    fullscreen: "Helskärm",
    maximize: "Maximera",
    float: "Flytande",
    pin: "Fäst",
    close: "Stäng",
    toggleSplit: "Växla delning",
    swapSides: "Byt sida",
    ratioHint: "Vänster eller övre | höger eller nedre",
    arrowsHint: "Pilar: byt med grannen",
    numbersHint: "Siffror: skicka till arbetsyta",
    toDisplay: "Till skärm:",
    layout: "Layout: %1",
    gaps: "Mellanrum",
    workspaceToDisplay: "Flytta arbetsytan till:",
    laptopDisplay: "Bärbar skärm",
    mirrorLaptop: "Spegla bärbar",
    laptop: "Bärbar",
    errStatus: "Kunde inte läsa fönsterstatus",
    errWindowGone: "Fönstret finns inte längre",
    errInvalid: "Ogiltig begäran",
    errRefused: "Hyprland avvisade åtgärden",
    errFailed: "Något gick fel"
  }
}

function resolve(setting, systemLanguage) {
  var lang = String(setting || "auto").toLowerCase()
  if (lang === "auto") lang = String(systemLanguage || "").toLowerCase().slice(0, 2)
  return dictionaries[lang] ? lang : "en"
}

// tr(lang, key, arg1, arg2, ...) fills %1, %2, ... in order.
function tr(lang, key) {
  var dict = dictionaries[lang] || dictionaries.en
  var text = dict[key] !== undefined ? dict[key] : (dictionaries.en[key] !== undefined ? dictionaries.en[key] : key)
  for (var i = 2; i < arguments.length; i++)
    text = text.split("%" + (i - 1)).join(String(arguments[i]))
  return text
}

// The script reports failures as a code on stderr ("window_gone",
// "invalid:...", "refused:..."); map it to a message in the panel language.
function errorText(lang, raw) {
  var code = String(raw || "").split(":")[0].trim()
  switch (code) {
  case "no_window": return tr(lang, "noWindow")
  case "window_gone": return tr(lang, "errWindowGone")
  case "invalid": return tr(lang, "errInvalid")
  case "refused": return tr(lang, "errRefused")
  default: return tr(lang, "errFailed")
  }
}
