--!nonstrict

--[=[
	@class MenuPromptService
]=]

local require = require(script.Parent.loader).load(script)

local Blend = require("Blend")
local GameScalingUtils = require("GameScalingUtils")
local Maid = require("Maid")
local MenuPrompt = require("MenuPrompt")
local MenuPromptScreenGuiProvider = require("MenuPromptScreenGuiProvider")
local Observable = require("Observable")
local Promise = require("Promise")
local PromptQueue = require("PromptQueue")
local ServiceBag = require("ServiceBag")

local MenuPromptService = {}
MenuPromptService.ServiceName = "MenuPromptService"

export type MenuPromptService = typeof(setmetatable(
	{} :: {
		_maid: Maid.Maid,
		_queue: PromptQueue.PromptQueue,
		_screenGui: ScreenGui
	},
	{} :: typeof({__index = MenuPromptService})
))

function MenuPromptService.Init(self: MenuPromptService, serviceBag: ServiceBag.ServiceBag)
	self._maid = Maid.new()
	self._queue = self._maid:Add(PromptQueue.new())
	self._screenGui = self._maid:Add(serviceBag:GetService(MenuPromptScreenGuiProvider):Get("MENU_PROMPT"))
end

function MenuPromptService._renderUICorner(self: MenuPromptService, object: GuiObject): Observable.Observable<UICorner>
	return Blend.New "UICorner" {
		CornerRadius = GameScalingUtils.observeDialogPadding(self._screenGui),
		Parent = object
	}
end

function MenuPromptService.SetScreenGui(self: MenuPromptService, screenGui: ScreenGui): MenuPromptService
	self._screenGui = screenGui or error("No ScreenGui")

	return self
end

function MenuPromptService.PushPrompt(self: MenuPromptService, promptBodyBuilder: MenuPrompt.PromptBodyBuilder): MenuPrompt.MenuPrompt
	local maid = Maid.new()

	local prompt = maid:Add(MenuPrompt.new(promptBodyBuilder))
	prompt.Gui.Parent = self._screenGui

	maid:GiveTask(GameScalingUtils.renderDialogPadding{
		Parent = prompt.Gui,
		ScreenGui = self._screenGui
	}:Subscribe())
	maid:GiveTask(self:_renderUICorner(prompt.Gui):Subscribe())

	self._maid:GivePromise(self._queue:Queue(prompt)):Finally(function()
		maid:DoCleaning()
	end)

	return prompt
end

function MenuPromptService.HideCurrent(self: MenuPromptService, doNotAnimate: boolean?): Promise.Promise<()>
	return self._queue:HideCurrent(doNotAnimate)
end

function MenuPromptService.Clear(self: MenuPromptService, doNotAnimate: boolean?)
	self._queue:Clear(doNotAnimate)
end

function MenuPromptService.ObserveIsShowing(self: MenuPromptService): Observable.Observable<boolean>
	return self._queue:ObserveIsShowing()
end

function MenuPromptService.Destroy(self: MenuPromptService)
	self._maid:DoCleaning()
end

return MenuPromptService