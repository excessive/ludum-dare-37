local talkback = {
  _VERSION     = 'Talkback v1.0.1',
  _DESCRIPTION = 'A tiny observer pattern library for Lua',
  _URL         = 'https://github.com/tesselode/talkback',
  _LICENSE     = [[
    The MIT License (MIT)

    Copyright (c) 2015 Andrew Minnich

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
  ]]
}

local function removeByValue(t, value)
  for i = #t, 1, -1 do
    if t[i] == value then
      table.remove(t, i)
      break
    end
  end
end

local Conversation = {}
Conversation.__index = Conversation

function Conversation:listen(s, f)
  assert(s, 's must not be a nil value')
  assert(type(f) == 'function', 'f should be a function')

  local listener = {s = s, f = f}
  table.insert(self.listeners, listener)
  return listener
end

function Conversation:newGroup(...)
  local group = {isGroup = true, listeners = {}}

  function group.listen(g, s, f)
    assert(type(f) == 'function', 'f should be a function')
    table.insert(g.listeners, self:listen(s, f))
  end

  return group
end

function Conversation:stopListening(listener)
  if listener.isGroup then
    --remove groups of listeners
    for i = 1, #listener.listeners do
      removeByValue(self.listeners, listener.listeners[i])
    end
  else
    --remove single listeners
    removeByValue(self.listeners, listener)
  end
end

function Conversation:say(s, ...)
  local returned = {}
  for i = 1, #self.listeners do
    local listener = self.listeners[i]
    if s == listener.s then
      local returnedValues = {listener.f(...)}
      for j = 1, #returnedValues do
        table.insert(returned, returnedValues[j])
      end
    end
  end
  return unpack(returned)
end

function talkback.new()
  local conversation = setmetatable({}, Conversation)
  conversation.listeners = {}
  return conversation
end

return talkback
