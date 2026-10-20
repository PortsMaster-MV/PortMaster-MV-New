local Natives = {}

Natives.BY_NAME = {
  -- pokeemerald/src/easy_chat.c:5378
  ShowEasyChatProfile = function(ctx, adapters)
    local Runtime = package.loaded["src.core.game3.runtime"]
    local session = Runtime and Runtime.getSession and Runtime.getSession()
    local EasyChatText = require("src.core.game3.easy_chat_text")
    local words = session and session.easyChatProfile or EasyChatText.DEFAULT_PROFILE
    local text = EasyChatText.phrase(words, 2, 2)
    if ctx and ctx.stringVars then ctx.stringVars[4] = text end
    if adapters and adapters.openMessageAsync then
      return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
        adapters.openMessageAsync(text, done)
      end)
    elseif adapters and adapters.openMessage then
      adapters.openMessage(text)
    end
    return false
  end,
}

return Natives
