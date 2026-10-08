-- src/item_menu.c:1787 Task_ItemContext_Sell, src/tm_case.c:1157 Task_SelectedTMHM_Sell

local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local ItemsData = require("src.core.game3.items_data")
local Bag = require("src.core.game3.bag")
local RomText = require("src.core.game3.rom_text")
local Trig = require("src.core.game3.trig")

local SellFlow = {}
SellFlow.__index = SellFlow

-- include/constants/songs.h:254
local SE = require("src.core.game3.se_ids")

local function se(id)
  pcall(function() require("src.core.game3.audio").playSe(id) end)
end

local function is_rse(session)
  return require("src.core.game3.profile").family(session) == "rse"
end

local function box(self, key, ctx)
  if self.nativeShop then return self.nativeShop.box(key, ctx) end
  return RomText.box(key, ctx)
end

local function price_of(itemId)
  local info = ItemsData.info(itemId)
  return math.max(0, math.floor(tonumber(info and info.price) or 0))
end

-- src/field_specials.c:1548 ContextNpcGetTextColor, src/menu_helpers.c:237 GetDialogBoxFontId
local function dialog_colors()
  local Space = package.loaded["src.core.game3.scripting.space"]
  local ctx = Space and Space.vm and Space.vm.ctx
  local c = FrlgFont.NPC_TEXT_COLOR.NEUTRAL
  if ctx then
    local Adapters = require("src.core.game3.scripting.adapters")
    c = Adapters.resolveNpcColor(ctx, Space.store)
  end
  if c == FrlgFont.NPC_TEXT_COLOR.MALE then return FrlgFont.COLOR.MALE_NPC end
  return FrlgFont.COLOR.FEMALE_NPC
end

function SellFlow.start(opts)
  local self = setmetatable({}, SellFlow)
  self.itemId = opts.itemId
  self.name = ItemsData.displayName(opts.itemId)
  self.session = opts.session
  local ui = require("src.core.game3.profile").forSession(self.session).ui
  local shop = ui and ui.shopMenu
  self.nativeShop = type(shop) == "string" and require(shop) or shop
  self.bag = opts.bag
  self.onDone = opts.onDone
  self.qty = 1
  self.yesNo = 1
  self.k = 0
  self.unit = math.floor(price_of(opts.itemId) / 2)
  self.colors = dialog_colors()
  if price_of(opts.itemId) == 0 then
    self.state = "cant"
    if is_rse(self.session) then
      self.text = box(self, "gText_CantBuyKeyItem", { stringVars = { [2] = self.name } })
    else
      self.text = RomText.box("gText_OhNoICantBuyThat", { stringVars = { self.name } })
    end
    self.textColors = self.colors
    return self
  end
  local owned = math.max(1, tonumber(opts.owned) or 1)
  self.owned = math.min(self:rseBerry() and 999 or 99, owned)
  if owned == 1 and not (self.nativeShop and self.nativeShop.alwaysQuantity) then
    self:ask()
  else
    self.state = "qty"
    if is_rse(self.session) then
      self.text = box(self, "gText_HowManyToSell", { stringVars = { [2] = self.name } })
    else
      self.text = RomText.box("gText_HowManyWouldYouLikeToSell", { stringVars = { self.name } })
    end
    self.textColors = self.colors
  end
  return self
end

function SellFlow:rseBerry()
  if not is_rse(self.session) then return false end
  local ok, BagMenu = pcall(require, "src.ui.game3.bag_menu")
  return ok and BagMenu.currentPocket and BagMenu.currentPocket() == "BERRY_POUCH" or false
end

function SellFlow:total()
  return self.unit * self.qty
end

-- src/item_menu.c:1840 Task_PrintSaleConfirmationText
function SellFlow:ask()
  self.state = "confirm"
  self.yesNo = 1
  if is_rse(self.session) then
    self.text = box(self, "gText_ICanPayVar1", { stringVars = { tostring(self:total()) } })
  else
    self.text = RomText.box("gText_ICanPayThisMuch_WouldThatBeOkay",
      { stringVars = { [3] = tostring(self:total()) } })
  end
  self.textColors = self.colors
end

-- src/item_menu.c:1917 Task_SellItem_Yes, :1928 Task_FinalizeSaleToShop
function SellFlow:commit()
  local earn = self:total()
  if is_rse(self.session) then
    self.text = box(self, "gText_TurnedOverVar1ForVar2", { stringVars = { tostring(earn), self.name } })
  else
    self.text = RomText.box("gText_TurnedOverItemsWorthYen",
      { stringVars = { self.name, [3] = tostring(earn) } })
  end
  self.textColors = FrlgFont.COLOR.NORMAL
  self.state = "done"
  se(SE.SE_SHOP)
  if self.bag and Bag.remove(self.bag, self.itemId, self.qty) and self.session then
    self.session.money = math.max(0, math.floor(tonumber(self.session.money) or 0)) + earn
    if self.nativeShop and self.nativeShop.saleMoney then self.session.money = self.nativeShop.saleMoney(self.session.money) end
    if not self.nativeShop or self.nativeShop.questLog ~= false then
      local Q = require("src.core.game3.quest_log_recorder")
      local rt = package.loaded["src.core.game3.runtime"]
      Q.event(self.session, "SoldItemsIncludingItem",
        { D0 = Q.location(rt and rt._game, self.session), D1 = self.name, D2 = earn })
    end
  end
  self.sold = true
end

function SellFlow:finish()
  self.state = nil
  local cb = self.onDone
  self.onDone = nil
  if cb then cb(self.sold == true) end
end

function SellFlow:active()
  return self.state ~= nil
end

-- src/menu_helpers.c:169 AdjustQuantityAccordingToDPadInput
local function adjust(q, qmax, input)
  local before = q
  if input:wasPressed("up") then
    q = q + 1
    if q > qmax then q = 1 end
  elseif input:wasPressed("down") then
    q = q - 1
    if q <= 0 then q = qmax end
  elseif input:wasPressed("right") then
    q = math.min(qmax, q + 10)
  elseif input:wasPressed("left") then
    q = math.max(1, q - 10)
  end
  return q, q ~= before
end

function SellFlow:handleInput(input)
  self.k = self.k + 1
  local st = self.state
  if st == "cant" or st == "done" then
    if input:wasPressed("a") or (input:wasPressed("b") and
      not (st == "done" and self.nativeShop and self.nativeShop.doneCancel == false)) then
      se(SE.SE_SELECT)
      self:finish()
    end
  elseif st == "qty" then
    local q, changed = adjust(self.qty, self.owned, input)
    if changed then
      self.qty = q
      se(SE.SE_SELECT)
    elseif input:wasPressed("a") then
      se(SE.SE_SELECT)
      self:ask()
    elseif input:wasPressed("b") then
      se(SE.SE_SELECT)
      self:finish()
    end
  elseif st == "confirm" then
    -- src/menu_helpers.c:47 Task_CallYesOrNoCallback
    if input:wasPressed("up") and self.yesNo ~= 1 then
      self.yesNo = 1
      se(SE.SE_SELECT)
    elseif input:wasPressed("down") and self.yesNo ~= 2 then
      self.yesNo = 2
      se(SE.SE_SELECT)
    elseif input:wasPressed("a") then
      se(SE.SE_SELECT)
      if self.yesNo == 1 then self:commit() else self:finish() end
    elseif input:wasPressed("b") then
      se(SE.SE_SELECT)
      self:finish()
    end
  end
end

-- src/menu_indicators.c:270 SpriteCallback_ScrollIndicatorArrow
local function bob(k, freq)
  local v = Trig.sin((k * freq) % 256) * 2 / 256
  return v < 0 and math.ceil(v) or math.floor(v)
end

-- src/money.c:90 PrintMoneyAmount
local function money_string(amount)
  local digits = tostring(math.floor(amount))
  return string.rep(" ", math.max(0, 6 - #digits))
    .. RomText.plain("gText_PokedollarVar1", { stringVars = { digits } })
end

-- src/money.c:107 PrintMoneyAmountInMoneyBoxWithBorder
local function draw_money_box(amount)
  Window.stdFrame(Window.template(1, 1, 8, 3))
  Window.printPx(RomText.plain("gText_TrainerCardMoney"), 8, 8)
  local s = money_string(amount)
  local w = FrlgFont.measure(s, { small = true })
  Window.printPx(s, 8 + 64 - w, 8 + 12, { small = true })
end

-- pokeemerald/src/item_menu.c:2120 InitSellHowManyInput, :1201 PrintItemSoldAmount
function SellFlow:drawRse()
  if self.nativeShop and self.nativeShop.drawSell then return self.nativeShop.drawSell(self) end
  local st = self.state
  local Shop = require("src.ui.game3.rse.shop_menu")
  local Chrome = require("src.ui.game3.chrome")
  if st ~= "cant" then
    Shop.drawMoneyBox(tonumber(self.session and self.session.money) or 0)
  end
  Window.dialogueFrame()
  local w = Chrome.DLG_W * 8
  FrlgFont.draw(FrlgFont.wrap(self.text, w), Chrome.DLG_LEFT * 8, Chrome.DLG_TOP * 8 + 1,
    { maxWidth = w, colors = FrlgFont.COLOR.NORMAL })
  if st == "qty" then
    local q = Shop.WIN.qty
    Window.stdFrame(q)
    Window.fill(q, 1, 1, 1, 1)
    local digits = self:rseBerry() and 3 or 2
    Window.printPx(RomText.plain("gText_xVar1", { stringVars = { string.format("%0" .. digits .. "d", self.qty) } }),
      q.left * 8, q.top * 8 + 1)
    Shop.drawMoneyAmount(nil, q, self:total())
  elseif st == "confirm" then
    local yn = Shop.WIN.yesno
    Window.stdFrame(yn)
    Window.fill(yn, 1, 1, 1, 1)
    local pitch = Window.optionHeight()
    Window.printPx(RomText.plain("gText_Yes"), yn.left * 8 + 8, yn.top * 8 + 1)
    Window.printPx(RomText.plain("gText_No"), yn.left * 8 + 8, yn.top * 8 + 1 + pitch)
    Window.cursorPx(yn.left * 8, yn.top * 8 + 1 + (self.yesNo - 1) * pitch)
  end
end

function SellFlow:draw()
  local st = self.state
  if not st then return end
  if is_rse(self.session) then return self:drawRse() end
  local Chrome = require("src.ui.game3.chrome")
  if st ~= "cant" then
    draw_money_box(tonumber(self.session and self.session.money) or 0)
  end
  -- src/item_menu.c:1021 DisplayItemMessageInBag
  Window.dialogueFrame()
  local w = Chrome.DLG_W * 8
  FrlgFont.draw(FrlgFont.wrap(self.text, w), Chrome.DLG_LEFT * 8, Chrome.DLG_TOP * 8 + 1,
    { maxWidth = w, colors = self.textColors })
  if st == "qty" then
    -- src/bag.c:87 sWindowTemplates[1], src/item_menu.c:1866
    Window.stdFrame(Window.template(17, 9, 12, 4))
    FrlgFont.draw(RomText.plain("gText_TimesStrVar1", { stringVars = { string.format("%02d", self.qty) } }),
      136 + 4, 72 + 10, { small = true, letterSpacing = 1, colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(money_string(self:total()), 136 + 56, 72 + 10, { small = true, colors = FrlgFont.COLOR.NORMAL })
    -- src/item_menu.c:781 CreatePocketScrollArrowPair_SellQuantity
    local okB, BagChrome = pcall(require, "src.ui.game3.bag_chrome")
    if okB and BagChrome and BagChrome.drawArrow then
      BagChrome.drawArrow("up", 152 - 8, 72 - 8 + bob(self.k, 8))
      BagChrome.drawArrow("down", 152 - 8, 104 - 8 + bob(self.k, -8))
    end
  elseif st == "confirm" then
    -- src/bag.c:299 BagCreateYesNoMenuTopRight, src/menu.c:531 CreateYesNoMenu
    Window.stdFrame(Window.template(21, 9, 6, 4))
    local x, y = 21 * 8, 9 * 8 + 2
    FrlgFont.draw(RomText.plain("gText_Yes"), x + 8, y, { colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(RomText.plain("gText_No"), x + 8, y + FrlgFont.LINE_PITCH, { colors = FrlgFont.COLOR.NORMAL })
    Window.cursorPx(x, y + (self.yesNo == 2 and FrlgFont.LINE_PITCH or 0))
  end
end

return SellFlow
