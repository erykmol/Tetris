dofile( "table.save-1.0.lua" )

local blocksListSize = 30
local areaWidth = 10
local areaHeight = 20

local blocks = {
  {
    { 0,0,1,0 },
    { 0,0,1,0 },
    { 0,0,1,0 },
    { 0,0,1,0 }
  },
  {
    { 1,1 },
    { 1,1 }
  },
  {
    { 1,0,0 },
    { 1,1,0 },
    { 0,1,0 }
  },
  {
    { 0,1,0 },
    { 0,1,0 },
    { 1,1,0 }
  }
}
  
local shape
local shapePosX
local shapePosY
local shapeFall
local nextShape

local blocksList

local score
local gameOver

local timer
local interval = 0.05
local controlTimer
local controlInterval = 0.07
local collectTimer
local collectInterval = 0.15

function resetShape()
  local shapeType

  if nextShape ~= nil then
    shapeType = nextShape.type
  else
    shapeType = love.math.random(1, #blocks)
  end

  shape = createShape(shapeType)
  shapePosX = math.floor(areaWidth / 2 - (shape.maxX - shape.minX) / 2 - shape.minX + 0.5)
  shapePosY = -shape.minY + 1
  shapeFall = 0
  
  local nextShapeType = love.math.random(1, #blocks)
  nextShape = createShape(nextShapeType)
  
  if isShapeColliding(shapePosX, shapePosY) then
    gameOver = true
  end
end

function restart()
  gameOver = false
  clearblocksList()
  nextShape = nil
  resetShape()
  score = 0
  timer = 0
  controlTimer = 0
  collectTimer = 0
end

function clearblocksList()
  blocksList = {}
  
  for j = 1, areaHeight do
    blocksList[j] = {}
    
    for i = 1, areaWidth do
      blocksList[j][i] = 0
    end
  end
end

function saveShape()
  for j = 1, shape.length do
    for i = 1, shape.length do
      if shape.data[j][i] == 1 then
        local x = shapePosX + i
        local y = shapePosY + j
        
        if x >= 1 and x <= areaWidth and y >= 1 and y <= areaHeight then
          blocksList[y][x] = shape.type
        end
      end
    end
  end
end

function markblocksList()
  local temp = {}
  
  for j = 1, areaHeight do
    temp[j] = {}
    
    for i = 1, areaWidth do temp[j][i] = 0 end
  end
  
  local marked = false
  
  for j = areaHeight, 1, -1 do
    local mark = true
    
    for i = 1, areaWidth do
      if blocksList[j][i] == 0 then mark = false; break end
    end
    
    if mark then
      for i = 1, areaWidth do temp[j][i] = 8 end
      score = score + areaWidth * 10
      marked = true
    else
      for i = 1, areaWidth do temp[j][i] = blocksList[j][i] end
    end
  end
  
  if marked then
    score = score + areaWidth * 10
    collectTimer = 0
  end
  
  for j = 1, areaHeight do
    for i = 1, areaWidth do blocksList[j][i] = temp[j][i] end
  end
end

function collectblocksList()
  local temp = {}
  
  for j = 1, areaHeight do
    temp[j] = {}
    
    for i = 1, areaWidth do temp[j][i] = 0 end
  end
  
  local row = areaHeight
  
  for j = areaHeight, 1, -1 do
    local copy = false
    
    for i = 1, areaWidth do
      if blocksList[j][i] < 8 then copy = true; break end
    end
    
    if copy then
      for i = 1, areaWidth do temp[row][i] = blocksList[j][i] end
      row = row - 1
    end
  end
  
  for j = 1, areaHeight do
    for i = 1, areaWidth do blocksList[j][i] = temp[j][i] end
  end
end

function createShape(t)
  local shape = {
    type = t,
    length = #blocks[t][1],
    minX = 100,
    maxX = -100,
    minY = 100,
    maxY = -100,
    data = {}
  }

  for y = 1, shape.length do
    shape.data[y] = {}
    
    for x = 1, shape.length do
      local u = x
      local v = y
      
      if r == 2 then
        u = y
        v = shape.length - x + 1
      elseif r == 3 then
        u = shape.length - x + 1
        v = shape.length - y + 1
      elseif r == 4 then
        u = shape.length - y + 1
        v = x
      end
      
      shape.data[y][x] = blocks[t][v][u]
      
      if shape.data[y][x] == 1 then
        if x < shape.minX then shape.minX = x end
        if x > shape.maxX then shape.maxX = x end
        if y < shape.minY then shape.minY = y end
        if y > shape.maxY then shape.maxY = y end
      end
    end
  end
    
  return shape
end

function isShapeColliding(x, y)
  local minX = -shape.minX + 1
  local minY = -shape.minY + 1
  local maxX = areaWidth - shape.maxX
  local maxY = areaHeight - shape.maxY
  if x < minX then return true end
  if y < minY then return true end
  if x > maxX then return true end
  if y > maxY then return true end
  
  for j = 1, shape.length do
    for i = 1, shape.length do
      if shape.data[j][i] == 1 then
        local px = x + i
        local py = y + j
        
        if px >= 1 and px <= areaWidth and py >= 1 and py <= areaHeight and blocksList[py][px] > 0 then
          return true
        end
      end
    end
  end
  
  return false
end

function loadGame()
  blocksList = table.load("save.txt")
  local file, err = io.open("saveOtherData.txt")
  if file then
    score = file:read("number")
    file:close()
  else
    print("error:", err)
  end
end

function saveGame()
  table.save(blocksList, "save.txt")
  local file,err = io.open("saveOtherData.txt",'w')
    if file then
        file:write(tostring(score).."\n")
        file:close()
    else
        print("error:", err)
    end
end

function drawBlock(t, x, y)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", blocksListSize * x + 6, blocksListSize * y + 6, blocksListSize, blocksListSize)
end

function drawShape(s, x, y)  
  for j = 1, s.length do
    for i = 1, s.length do
      if s.data[j][i] == 1 then drawBlock(s.type, x + i - 1, y + j - 1) end
    end
  end
end

function drawArea()
  for j = 1, areaHeight do
    for i = 1, areaWidth do
      if blocksList[j][i] ~= 0 then
        drawBlock(blocksList[j][i], i - 1, j - 1)
      end
    end
  end
end

function drawGUI()
  local sw = love.graphics.getWidth()
  local aw = blocksListSize * areaWidth
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.printf("NEXT", aw, blocksListSize * 0.5, sw - aw, "center")
  love.graphics.printf("SCORE", aw, blocksListSize * 7.0, sw - aw, "center")
  love.graphics.printf("PRESS L\n TO\n LOAD SAVE", aw, blocksListSize * 10, sw - aw, "center")
  love.graphics.printf("PRESS S\n TO\n SAVE GAME", aw, blocksListSize * 15, sw - aw, "center")

  love.graphics.setColor(180, 180, 180)
  love.graphics.printf(score, aw, blocksListSize * 8.5, sw - aw, "center")
  
  local px = areaWidth + 3.5 - (nextShape.maxX - nextShape.minX) / 2 - nextShape.minX
  drawShape(nextShape, px, 3.0 - nextShape.minY)
end

function love.load()
  love.window.setMode(blocksListSize * (areaWidth + 6), blocksListSize * areaHeight)
  love.window.setTitle("Tetris")
  local font = love.graphics.newFont(blocksListSize)
  love.graphics.setFont(font)
  restart()
end

function love.update(dt)
  if gameOver then return end
  
  controlTimer = controlTimer + dt
  if controlTimer >= controlInterval then
    controlTimer = 0
    
    if love.keyboard.isDown("left") and not isShapeColliding(shapePosX - 1, shapePosY) then
      shapePosX = shapePosX - 1
    end
    
    if love.keyboard.isDown("right") and not isShapeColliding(shapePosX + 1, shapePosY) then
      shapePosX = shapePosX + 1
    end

    if love.keyboard.isDown("down") and not isShapeColliding(shapePosX, shapePosY + 1) then
      shapePosY = shapePosY + 1
      score = score + 10
    end
  end

  collectTimer = collectTimer + dt
  if collectTimer >= collectInterval then
    collectTimer = 0
    collectblocksList()
  end
  
  timer = timer + dt
  while timer >= interval do
    timer = timer - interval 
    
    shapeFall = shapeFall + 1
    if shapeFall >= 20 then
      shapeFall = 0
      
      if isShapeColliding(shapePosX, shapePosY + 1) then
        saveShape()
        markblocksList()
        resetShape()
      else
        shapePosY = shapePosY + 1
        score = score + 10
      end
    end
  end
end

function love.draw()
  if gameOver then
    local sw, sh = love.graphics.getDimensions()
    local sw2, sh2 = sw / 2, sh / 2
    
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf("GAME OVER!", 0, sh2 - blocksListSize * 3.5, sw, "center")
    love.graphics.printf("Press ENTER to restart!", 0, sh2 + blocksListSize * 2.5, sw, "center")
  
    love.graphics.setColor(180, 180, 180)
    love.graphics.printf("Score: " .. score, 0, sh2 - blocksListSize * 1.5, sw, "center")
  else
    drawArea()
    drawShape(shape, shapePosX, shapePosY)
    drawGUI()
  end
end

function love.keyreleased(key)
  if key == "escape" then love.event.quit() end
  if key == "return" and gameOver then restart() end
  if key == "r" then restart() end
  if key == "s" then saveGame() end
  if key == "l" then loadGame() end

  if key == "up" then
    local oldShapePosX = shapePosX
    local oldShapePosY = shapePosY
    local oldShapeType = shape.type
    
    shape = createShape(shape.type)
  
    local minX = -shape.minX + 1
    local minY = -shape.minY + 1
    local maxX = areaWidth - shape.maxX
    local maxY = areaHeight - shape.maxY
    if shapePosX < minX then shapePosX = minX end
    if shapePosY < minY then shapePosY = minY end
    if shapePosX > maxX then shapePosX = maxX end
    if shapePosY > maxY then shapePosY = maxY end
  
    if isShapeColliding(shapePosX, shapePosY) then
      shape = createShape(oldShapeType)
      shapePosX = oldShapePosX
      shapePosY = oldShapePosY
    end
  end
end