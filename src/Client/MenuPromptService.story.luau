--!nonstrict
--[[
    @class menuPromptService.story
]]

local require = (require :: any)(
    game:GetService("ServerScriptService"):FindFirstChild("LoaderUtils", true).Parent
).bootstrapStory(script) :: typeof(require(script.Parent.loader).load(script))

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local Maid = require("Maid")
local MenuPrompt = require("MenuPrompt")
local MenuPromptService = require("MenuPromptService")
local PromiseUtils = require("PromiseUtils")
local ScreenGuiService = require("ScreenGuiService")
local ServiceBag = require("ServiceBag")

return function(target): () -> ()
    local maid = Maid.new()
    local serviceBag = maid:Add(ServiceBag.new())

    local menuPromptService = serviceBag:GetService(MenuPromptService)
    maid:GiveTask(serviceBag:GetService(ScreenGuiService):SetGuiParent(target))

    serviceBag:Init()
    serviceBag:Start()

    local function buildPrompt(prompt: MenuPrompt.MenuPrompt, innerMaid: Maid.Maid)
        prompt:SetPromiseSustain(function()
            return PromiseUtils.delayed(10)
        end)

        local label = innerMaid:Add(Instance.new("TextLabel"))
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "Hello, world!"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true

        return BasicPane.new(label)
    end

    local function showPrompt()
        menuPromptService:PushPrompt(buildPrompt)
    end

    local function button(props)
        return Blend.New "TextButton" {
            AutomaticSize = Enum.AutomaticSize.XY,
            AutoButtonColor = true,
            Text = props.Text,
            [Blend.OnEvent "Activated"] = props.OnActivated,
            Blend.New "UIPadding" {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            },
            Blend.New "UICorner" {
                CornerRadius = UDim.new(0, 5)
            }
        }
    end

    showPrompt()

    maid:GiveTask(Blend.mount(target, {
        Blend.New "Frame" {
            AutomaticSize = Enum.AutomaticSize.XY,
            Position = UDim2.new(),
            BackgroundTransparency = 1,
            Blend.New "UIPadding" {
                PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
            },
            Blend.New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5)
            },
            button({
                Text = "Show Prompt",
                OnActivated = showPrompt
            }),
            button({
                Text = "Clear Queue",
                OnActivated = function()
                    menuPromptService:ClearQueue()
                end
            }),
            button({
                Text = "Hide Current",
                OnActivated = function()
                    menuPromptService:ClearQueue()
                end
            })
        }
    }))

    return function()
        maid:DoCleaning()
    end
end