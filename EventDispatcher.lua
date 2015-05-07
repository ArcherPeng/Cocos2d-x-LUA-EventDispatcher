--[[
-------------------------------------------------
    EventDispatcher.lua
    Created by ArcherPeng on 15-01-04.
-------------------------------------------------
功能概述：
本模块实现事件分发机制。可大幅降低各模块间的耦合,将事件调用从各模块中分离出来,接收方无需知道派发者是谁。
该类主要用于网络通讯数据的分发。
在世界分发的接收方法中,如果返回true,将默认为本次分发已被处理，将终止后续分发。
若无返回,或返回为false,将继续事件的后续分发。
注:如果为静态方法，objec写nil
-------------------------------------------------
用法简述
function GameScene:callback(eventKey,msg)
    print("eventName:["..eventKey.."]--msg:["..msg.."]--end")
    return true -- 该事件已消费,终止后续分发流程
end

在GameScene:CreateLayer()中
--添加事件监听
local eventDispatcher=require("APUtils.EventDispatcher"):getInstance()
eventDispatcher:Add("12_33",GameScene.callback,self)

eventDispatcher = nil

--分发事件
eventDispatcher=require("APUtils.EventDispatcher"):getInstance()
eventDispatcher:Dispatch("12_33","12_33 received!")


数据层次结构
["eventKey1"] =
{
["_StaticFunc"] = { func1, func2 },

[object1] = { func1, func2 },
[object2] = { func1, func2 },
},
["eventKey2"] =
{
...
}
]]
local Global = _G
local package = _G.package
local setmetatable = _G.setmetatable
local assert = _G.assert
local table = _G.table
local pairs = _G.pairs
local ipairs = _G.ipairs
local EventDispatcher = class("APUtils.EventDispatcher")
 
-- 默认调用函数
function EventDispatcher:preInvoke( eventKey, func, object, userData, ... )
    if object then
        return func( object, eventKey, ... )
    else
        return func( eventKey, ... )
    end
 
end
function EventDispatcher:ctor( )    
    -- 对象成员初始化
    self.eventTable = {}
end
 
-- 添加
function EventDispatcher:add( eventKey, func, object, userData )
    assert( func )
    self.eventTable[ eventKey ] = self.eventTable[ eventKey ] or {}
    
    local event = self.eventTable[ eventKey ]
    
    if not object then
        object = "_StaticFunc"
    end
    
    event[object] = event[object] or {}
    local objectEvent = event[object]
 
    objectEvent[func] = userData or true
    
end
 
-- 设置调用前回调
function EventDispatcher:setDispatchHook( hookFunc )
    
    self.preInvoke = hookFunc
end
 
 
-- 派发
function EventDispatcher:dispatch( eventKey, ... )
 
    assert( eventKey )
    
    local event = self.eventTable[ eventKey ]
    if not event then return end
    for object,objectFunc in pairs( event ) do
        
        if object == "_StaticFunc" then
                
            for func, userData in pairs( objectFunc ) do
                if self:preInvoke( eventKey, func, nil, userData, ... )  then return end
            end
            
        else
        
            for func, userData in pairs( objectFunc ) do
                if self:preInvoke( eventKey, func, object, userData, ... ) then return end
            end
        
        end
 
    end
 
end
 
-- 回调是否存在
function EventDispatcher:exist( eventKey )
 
    assert( eventKey )
    
    local event = self.eventTable[ eventKey ]
    
    if not event then
        return false
    end
    
    -- 需要遍历下map, 可能有事件名存在, 但是没有任何回调的
    for object,objectFunc in pairs( event ) do
    
        for func, _ in pairs( objectFunc ) do
            -- 居然有一个
            return true
        end
    
    end
    
    
    return false
    
end
 
-- 清除
function EventDispatcher:remove( eventKey, func, object )
    
    assert( func )
    
    local event = self.eventTable[ eventKey ]
    
    if not event then
        return
    end
    
    if not object then
        object = "_StaticFunc"
    end
    
    
    local objectEvent = event[object]
    
    if not objectEvent then
        return
    end
    
    objectEvent[func] = nil   
end
 
-- 清除对象的所有回调
function EventDispatcher:removeObjectAllFunc( eventKey, object )
 
    assert( object )
    
    local event = self.eventTable[ eventKey ]
    
    if not event then
        return
    end
    
    event[object] = nil
 
end
 
 
function EventDispatcher:getInstance()

    if _G.APUtils_EventDispatcher_Instance == nil then _G.APUtils_EventDispatcher_Instance = EventDispatcher.new() end return _G.APUtils_EventDispatcher_Instance
end
function EventDispatcher:destoryInstance()
    _G.APUtils_EventDispatcher_Instance = nil
end
return EventDispatcher

 
