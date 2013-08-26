import XMonad
import XMonad.Actions.FindEmptyWorkspace
import XMonad.Actions.GridSelect
import XMonad.Actions.SpawnOn
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeWindows
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Named
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Simplest
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig
import XMonad.Util.Run

import Data.Monoid
import Graphics.X11.ExtraTypes.XF86

dzenCommand   = "dzen2 $(~/.xmonad/dzen_flags)"
conkyCommand  = "conky -c ~/.xmonad/status/conky_dzen | " ++ dzenCommand
trayerCommand = "trayer --edge bottom --height 24 --SetPartialStrut true"

xmonadStatus = dzenCommand ++ " -xs 1 -w 50% -ta l"
systemStatus = conkyCommand ++ " -xs 1 -x 50% -w 50% -ta r"
trayerStatus = trayerCommand ++ " --transparent true --alpha 32 --tint 0x002b36"

(/->)   :: Monoid m => Query Bool -> Query m -> Query m
p /-> f =  p >>= \b -> if b then idHook else f
infix 0 /->

main = do
    dzenXmonad <- spawnPipe xmonadStatus
    dzenSystem <- spawnPipe systemStatus
    trayer     <- spawnPipe trayerStatus
    xmonad $ withUrgencyHook NoUrgencyHook $ ewmh $ defaultConfig
             { startupHook = ewmhDesktopsStartup
             , manageHook = manageSpawn <+> manageDocks <+> myManageHook
             , layoutHook = avoidStrutsOn [U] $ smartBorders $ myLayout
             , logHook    = dynamicLogWithPP defaultPP
                            { ppCurrent = dzenColor "#b58900" "" . wrap "[" "]"
                            , ppUrgent  = dzenColor "#dc322f" "" . wrap "(" ")"
                            , ppTitle   = dzenColor "#268bd2" "" . shorten 70
                            , ppOrder   = reverse
                            , ppOutput  = hPutStrLn dzenXmonad
                            } >> fadeWindowsLogHook myFadeHook
             , handleEventHook = ewmhDesktopsEventHook <+> fadeWindowsEventHook
             , normalBorderColor  = "#586e75"
             , focusedBorderColor = "#d33682"
             , modMask            = myModMask
             , terminal           = "xterm"
             , workspaces         = myWorkspaces
             }
             `additionalKeys`
             [ ((myModMask .|. shiftMask, xK_semicolon), spawn "gvim -f")
             , ((myModMask              , xK_p), spawnHere "~/.dotfiles/bin/dmenu_run")
             , ((myModMask .|. shiftMask, xK_p), spawn "xfrun4")
             , ((myModMask .|. shiftMask, xK_f), tagToEmptyWorkspace)
             , ((myModMask              , xK_f), viewEmptyWorkspace)
             , ((myModMask .|. shiftMask, xK_t), sendMessage $ ToggleStrut D)
             , ((myModMask              , xK_i),
                     goToSelected $ gsConfig gsColorizer)
             , ((myModMask, xK_q), spawn
                     "xmonad --recompile && (killall conky; killall trayer; xmonad --restart)")
             , ((myModMask, xK_grave), spawn "~/.dotfiles/bin/toggle_composite")
             , ((0       ,  xK_Print), spawn "xfce4-screenshooter -f")
             , ((mod1Mask,  xK_Print), spawn "xfce4-screenshooter -w")
             , ((shiftMask, xK_Print), spawn "xfce4-screenshooter -r")
             , ((myModMask .|. shiftMask, xK_l),
                     spawn "xscreensaver-command -lock")
             ]

myModMask = mod4Mask

gsConfig colorizer = (buildDefaultGSConfig colorizer)

gsColorizer = colorRangeFromClassName
    minBound           -- lowest inactive bg
    (0x77, 0x74, 0x6a) -- highest inactive bg
    (0xfd, 0xf6, 0xe3) -- active bg
    (0x93, 0xa1, 0xa1) -- inactive fg
    (0x65, 0x7b, 0x83) -- active fg

myWorkspaces = ["web", "vim"] ++ map show [3..7] ++ ["irc", "vm"]

myManageHook = composeOne
               [ isFullscreen                       -?> doFullFloat
               , isDialog                           -?> doCenterFloat
               , className =? "Gnuplot"             -?> doCenterFloat
               , className =? "Xfce4-notifyd"       -?> doIgnore
               , className =? "Xfrun4"              -?> doCenterFloat
               ]

myFadeHook = composeAll
             [ isUnfocused  --> transparency 0.125
             , isFullscreen --> opaque
             , isUnfocused  /-> opaque
             ]

tall = Tall nmaster delta ratio
  where
    tiled   = Tall nmaster delta ratio
    nmaster = 1
    ratio   = 1/2
    delta   = 3/100

wide = named "Wide" $ Mirror tall
tab  = named "Tabbed" $ tabbedBottom shrinkText defaultTheme
    { activeColor         = "#586e75"
    , activeBorderColor   = "#eee8d5"
    , activeTextColor     = "#eee8d5"

    , inactiveColor       = "#073642"
    , inactiveBorderColor = "#839496"
    , inactiveTextColor   = "#839496"

    , urgentColor         = "#586e75"
    , urgentBorderColor   = "#eee8d5"
    , urgentTextColor     = "#cb4b16"
    }

defaultLayout = tall ||| wide ||| tab

webLayout = tab ||| tall ||| wide

myLayout = onWorkspace "web" webLayout defaultLayout
