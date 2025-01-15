-- Chargement du module dfpwm pour la gestion audio et recherche du périphérique "speaker"
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()
 
-- Fonctions d'aide pour l'interface
local function pos(...) term.setCursorPos(...) end
local function cls() term.clear() end
local function tCol(...) term.setTextColor(...) end
local function bCol(...) term.setBackgroundColor(...) end
local function box(...) paintutils.drawFilledBox(...) end
local function line(...) paintutils.drawLine(...) end
 
-- Récupération de la taille du terminal
local x, y = term.getSize()
 
-- Variable globale pour contrôler la lecture
local isPlaying = false
local currentLink = nil
 
-- Fonction pour jouer un lien direct de manière non bloquante
local function playDirectLink(lien)
    local handle = assert(http.get(lien, nil, true))
    return function()
        local chunk = handle.read(16 * 1024)
        if chunk then
            local buffer = decoder(chunk)
            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
                if not isPlaying then
                    handle.close()
                    return false
                end
            end
            return true
        else
            handle.close()
            return false
        end
    end
end
 
-- Fonction pour dessiner le menu principal de l'interface
local function drawMenu()
    cls()
    box(1,1,x,y,colors.lightBlue) -- Fond d'écran
 
    local menuWidth = math.min(x - 2, 28)
    local menuHeight = math.min(y - 2, 4) -- Réduit encore la hauteur du menu
    local menuX = math.floor((x - menuWidth) / 2)
    local menuY = math.floor((y - menuHeight) / 2)
 
    box(menuX, menuY, menuX + menuWidth, menuY + menuHeight, colors.gray) -- Menu
    line(menuX, menuY, menuX + menuWidth, menuY, colors.lightGray) -- Barre du haut
    line(menuX + menuWidth - 2, menuY, menuX + menuWidth, menuY, colors.red) -- Zone de fermeture
 
    local inputWidth = menuWidth - 10
    line(menuX + 9, menuY + 2, menuX + 9 + inputWidth, menuY + 2, colors.black) -- Zone MUSIC
 
    tCol(colors.black) bCol(colors.red)
    pos(menuX + menuWidth - 1, menuY)
    write("X")
 
    tCol(colors.yellow) bCol(colors.gray)
    pos(menuX + 1, menuY + 2)
    write("MUSIC")
 
    tCol(colors.white) bCol(colors.black)
end
 
-- Fonction pour jouer de la musique
local function musicPlay()
    local menuX = math.floor((x - math.min(x - 2, 28)) / 2)
    local menuY = math.floor((y - math.min(y - 2, 4)) / 2)
    pos(menuX + 9, menuY + 2)
    local input = read()
    
    if input:sub(1,4) == "http" then
        if isPlaying then
            isPlaying = false -- Arrête la musique en cours
            os.sleep(0.5) -- Attente pour s'assurer que la lecture précédente est arrêtée
        end
        currentLink = input
        isPlaying = true
        playNextChunk = playDirectLink(currentLink)
    else
        print("Lien invalide")
        os.sleep(2)
    end
    drawMenu()
end
 
-- Fonction principale
local function main()
    drawMenu()
    
    while true do
        local event, button, mx, my = os.pullEvent()
        if event == "mouse_click" and button == 1 then
            local menuWidth = math.min(x - 2, 28)
            local menuHeight = math.min(y - 2, 4)
            local menuX = math.floor((x - menuWidth) / 2)
            local menuY = math.floor((y - menuHeight) / 2)
            local inputWidth = menuWidth - 10
 
            if mx >= menuX + 9 and mx <= menuX + 9 + inputWidth and my == menuY + 2 then
                musicPlay()
            elseif mx >= menuX + menuWidth - 2 and mx <= menuX + menuWidth and my == menuY then
                isPlaying = false -- Arrête la musique si elle est en cours
                os.reboot()
            end
        end
    end 
end
 
-- Modification du lancement du programme
parallel.waitForAny(
    main,
    function()
        while true do
            if isPlaying and playNextChunk then
                if not playNextChunk() then
                    isPlaying = false
                    drawMenu()
                end
            end
            os.sleep(0)
        end
    end
)