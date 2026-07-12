--!strict

local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local BasicPaneUtils = require("BasicPaneUtils")
local Blend = require("Blend")
local Maid = require("Maid")
local Observable = require("Observable")
local Promise = require("Promise")
local SpringTransitionModel = require("SpringTransitionModel")
local SustainModel = require("SustainModel")
local TransitionModel = require("TransitionModel")
local ValueObject = require("ValueObject")

local MenuPrompt = setmetatable({}, TransitionModel)
MenuPrompt.__index = MenuPrompt

export type MenuPrompt = typeof(setmetatable(
    {} :: {
        _percentVisibleModel: SpringTransitionModel.SpringTransitionModel<number>,
        _sustainModel: SustainModel.SustainModel,
        _backgroundColor: ValueObject.ValueObject<Color3>,
        _sizeValue: ValueObject.ValueObject<Vector2>,
        _buildPromptBody: PromptBodyBuilder
    },
    {} :: typeof({__index = MenuPrompt})
)) & TransitionModel.TransitionModel

export type PromptBodyBuilder = (MenuPrompt, Maid.Maid) -> BasicPane.BasicPane

function MenuPrompt.new(promptBodyBuilder: PromptBodyBuilder): MenuPrompt
    local self = setmetatable(TransitionModel.new() :: any, MenuPrompt)

    self._buildPromptBody = promptBodyBuilder

    self._percentVisibleModel = self._maid:Add(SpringTransitionModel.new())
    self._percentVisibleModel:SetSpeed(100)
    self._percentVisibleModel:SetEpsilon(1e-2)
    self._percentVisibleModel:BindToPaneVisbility(self)

    self._sustainModel = self._maid:Add(SustainModel.new())

    self._sizeValue = self._maid:Add(ValueObject.new(Vector2.new(4, 3), "Vector2"))
    self._backgroundColor = self._maid:Add(ValueObject.new(Color3.fromRGB(27, 42, 53), "Color3"))

    self._maid:GiveTask(self:_render():Subscribe(function(gui)
        self.Gui = gui
    end))

    self:SetPromiseShow(function(_, doNotAnimate)
        return self._percentVisibleModel:PromiseShow(doNotAnimate)
    end)
    self:SetPromiseHide(function(_, doNotAnimate)
        return self._percentVisibleModel:PromiseHide(doNotAnimate)
    end)

    return self
end

function MenuPrompt.SetPromiseSustain(self: MenuPrompt, callback: SustainModel.SustainCallback): ()
    self._sustainModel:SetPromiseSustain(callback)
end

function MenuPrompt.PromiseSustain(self: MenuPrompt, doNotAnimate: boolean?): Promise.Promise<()>
    return self._sustainModel:PromiseSustain(doNotAnimate)
end

function MenuPrompt.Stop(self: MenuPrompt, doNotAnimate: boolean?): ()
    self._sustainModel:Stop(doNotAnimate)
end

function MenuPrompt.SetSize(self: MenuPrompt, size: ValueObject.Mountable<Vector2>): () -> ()
    return self._sizeValue:Mount(size)
end

function MenuPrompt.SetBackgroundColor(self: MenuPrompt, color: ValueObject.Mountable<Color3>): () -> ()
    return self._backgroundColor:Mount(color)
end

function MenuPrompt._render(self: MenuPrompt): Observable.Observable<Instance>
    return Blend.New "Frame" {
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.75, 0.75),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self._backgroundColor,
        BackgroundTransparency = Blend.Computed(self._percentVisibleModel, function(alpha): number
            return 0.5 * (1 - alpha)
        end),
        Blend.New "UIAspectRatioConstraint" {
            AspectRatio = Blend.Computed(self._sizeValue, function(size): number
                if size.X <= 0 or size.Y <= 0 then
                    return 1
                else
                    return size.X / size.Y
                end
            end)
        },
        Blend.New "UIScale" {
            Scale = self._percentVisibleModel
        },
        (self:ObserveIsShowingComplete() :: any):Pipe{
            BasicPaneUtils.whenVisibleBrio(function(maid): BasicPane.BasicPane 
                return self:_buildPromptBody(maid)
            end)
        }
    }
end

return MenuPrompt
