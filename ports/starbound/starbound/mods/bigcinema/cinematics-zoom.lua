--
-- This mod doubles the size of cinematic radio messages so they're readable on small screens
--
function patch(cinematicConfig, path)
   -- Only process cinematic files (which have panels)
   if not cinematicConfig.panels then
      return cinematicConfig
   end
   
   -- Center point of the screen
   local centerX = 480
   
   -- Process each panel
   for _, panel in ipairs(cinematicConfig.panels) do
      -- Adjust textPosition if it exists.  We already doubled the font size in the code
      if panel.textPosition then
         -- Double the X and Y coordinates
         if panel.textPosition.position then
            panel.textPosition.position[1] = panel.textPosition.position[1] * 2
            panel.textPosition.position[2] = panel.textPosition.position[2] * 2
         end
         
         -- Double the wrapWidth if it exists
         if panel.textPosition.wrapWidth then
            panel.textPosition.wrapWidth = panel.textPosition.wrapWidth * 2
         end
      end
      
      if panel.keyframes then
         for _, keyframe in ipairs(panel.keyframes) do
            -- Adjust zoom from 1.0 to 2.0
            -- this is a big hack because it just happens that radio keyframes always zoom 1.0
            if keyframe.zoom == 1.0 then
               keyframe.zoom = 2.0

               -- Adjust X position if it exists
               if keyframe.position then
                  local currentX = keyframe.position[1]
                  local currentDistanceFromCenter = centerX - currentX
                  local newX = centerX - (currentDistanceFromCenter * 2)
                  
                  -- Update the position with the new X value, keep Y the same
                  keyframe.position[1] = newX
               end
            end
         end
      end
   end
   
   return cinematicConfig
end
