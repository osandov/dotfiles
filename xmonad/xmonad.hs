import XMonad
import XMonad.Actions.FindEmptyWorkspace
import XMonad.Actions.GridSelect
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.Named
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Simplest
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig
import XMonad.Util.Run
import Graphics.X11.ExtraTypes.XF86

dzenCommand  = "~/.xmonad/dzen"
conkyCommand = "conky -c ~/.xmonad/status/conky_dzen | " ++ dzenCommand

xmonadStatus = dzenCommand ++ " -w 683 -ta l"
systemStatus = conkyCommand ++ " -x 683 -w 683 -ta r"

main = do
    dzenXmonad <- spawnPipe xmonadStatus
    dzenSystem <- spawnPipe systemStatus
    xmonad $ defaultConfig
             { manageHook = manageDocks <+> myManageHook
             , layoutHook = avoidStruts $ smartBorders $ myLayout
             , logHook    = dynamicLogWithPP defaultPP
                            { ppCurrent = dzenColor "#b58900" "" . wrap "[" "]"
                            , ppUrgent  = dzenColor "#dc32ff" ""
                            , ppTitle   = dzenColor "#268bd2" "" . shorten 70
                            , ppOrder   = reverse
                            , ppOutput  = hPutStrLn dzenXmonad
                            } >> fadeInactiveLogHook 0xe0000000
             , normalBorderColor  = "#586e75"
             , focusedBorderColor = "#d33682"
             , modMask            = myModMask
             , workspaces         = myWorkspaces
             }
             `additionalKeys`
             [ ((myModMask .|. shiftMask, xK_semicolon), spawn "gvim -f")
             , ((myModMask .|. shiftMask, xK_p), spawn "xfrun4")
             , ((myModMask              , xK_m), viewEmptyWorkspace)
             , ((myModMask .|. shiftMask, xK_m), tagToEmptyWorkspace)
             , ((myModMask              , xK_i),
                     goToSelected $ gsConfig gsColorizer)
             , ((myModMask, xK_grave),
                     spawn "~/.xmonad/scripts/toggle_composite")
             , ((0       , xK_Print), spawn "xfce4-screenshooter -f")
             , ((mod1Mask, xK_Print), spawn "xfce4-screenshooter -r")
             , ((0, xF86XK_Sleep),
                     spawn "~/.xmonad/scripts/suspend")
             , ((0, xF86XK_AudioMute),
                     spawn "~/.xmonad/scripts/volume_set toggle")
             , ((0, xF86XK_AudioRaiseVolume),
                     spawn "~/.xmonad/scripts/volume_set 5%+")
             , ((0, xF86XK_AudioLowerVolume),
                     spawn "~/.xmonad/scripts/volume_set 5%-")
             ]

myModMask = mod4Mask

gsConfig colorizer = (buildDefaultGSConfig colorizer)

gsColorizer = colorRangeFromClassName
    minBound           -- lowest inactive bg
    (0x77, 0x74, 0x6a) -- highest inactive bg
    (0xfd, 0xf6, 0xe3) -- active bg
    (0x93, 0xa1, 0xa1) -- inactive fg
    (0x65, 0x7b, 0x83) -- active fg

myWorkspaces = ["web", "vim"] ++ map show [3..8] ++ ["vm"]

myManageHook = composeOne
               [ isFullscreen                       -?> doFullFloat
               , className =? "Gnuplot"             -?> doCenterFloat
               , resource  =? "xfrun4"              -?> doCenterFloat
               , title     =? "Downloads"           -?> doCenterFloat
               , title     =? "Firefox Preferences" -?> doCenterFloat
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
