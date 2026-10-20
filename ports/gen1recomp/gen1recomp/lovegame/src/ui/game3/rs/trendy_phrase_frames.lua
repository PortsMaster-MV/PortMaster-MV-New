local Shared = require("src.ui.game3.rs.mail_composer_frames")
local F = {begin = Shared.begin, step = Shared.step}
function F.initial(man)
  local map = {}; for i = 1, 640 do map[i] = man.maps.base[i] or 0 end
  local r = man.frame
  Shared.copy(map, r.x, r.y, man.maps.shapes, r.sourceX, r.sourceY, r.w, r.h)
  return map
end
return F
