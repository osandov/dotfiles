import XMonad
import XMonad.Actions.FindEmptyWorkspace
import XMonad.Actions.SpawnOn
import XMonad.Actions.SwapWorkspaces (swapWithCurrent)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeWindows
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Named
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Util.WorkspaceCompare

import qualified XMonad.StackSet as W

import Control.Monad (when)
import Data.Char (toLower)
import Data.List (elemIndex, sortBy)
import Data.Maybe (fromJust, isJust)
import Data.Monoid
import Data.Ord (comparing)


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
                            , ppLayout  = wrap "^i(.xmonad/icons/" ".xbm)" . (map toLower)
                            } >> fadeWindowsLogHook myFadeHook
                              >> wallpaperDLogHook
             , handleEventHook = ewmhDesktopsEventHook <+> fadeWindowsEventHook
             , normalBorderColor  = "#586e75"
             , focusedBorderColor = "#d33682"
             , modMask            = myModMask
             , terminal           = "xterm"
             , workspaces         = myWorkspaces
             } `additionalKeys` myKeys

myKeys = [ ((myModMask .|. shiftMask, xK_semicolon), spawn "gvim -f")
         , ((myModMask              , xK_p), spawnHere "~/.dotfiles/bin/dmenu_run")
         , ((myModMask .|. shiftMask, xK_p), spawn "xfrun4")
         , ((myModMask .|. shiftMask, xK_t), sendMessage $ ToggleStrut D)
         , ((myModMask, xK_q), spawn
                 "xmonad --recompile && (killall conky trayer; xmonad --restart)")
         , ((myModMask, xK_grave), spawn "~/.dotfiles/bin/toggle_composite")
         , ((0       ,  xK_Print), spawn "xfce4-screenshooter -f")
         , ((mod1Mask,  xK_Print), spawn "xfce4-screenshooter -w")
         , ((shiftMask, xK_Print), spawn "xfce4-screenshooter -r")
         , ((myModMask .|. shiftMask, xK_l),
                 spawn "~/.dotfiles/bin/lock_screensaver")
         , ((myModMask,                 xK_0), viewEmptyWorkspace)
         , ((myModMask .|. shiftMask,   xK_0), sendToEmptyWorkspace)
         , ((myModMask .|. controlMask, xK_0), tagToEmptyWorkspace)
         ] ++
         [ ((myModMask .|. controlMask, k), windows $ swapWithCurrent i)
           | (i, k) <- zip myWorkspaces [xK_1 ..]]

myModMask = mod4Mask

myWorkspaces = ["web", "vim"] ++ map show [3..6] ++ ["music", "irc", "vm"]

myManageHook = composeOne
               [ isFullscreen                 -?> doFullFloat
               , isDialog                     -?> doCenterFloat
               , className =? "Gnuplot"       -?> doCenterFloat
               , className =? "Xfce4-notifyd" -?> doIgnore
               , className =? "Xfrun4"        -?> doCenterFloat
               , return True                  -?> doF W.swapDown
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

wallpaperDLogHook :: X ()
wallpaperDLogHook = withWindowSet $ \s -> do
    sort' <- getSortByIndex
    let ws = sort' $ W.workspaces s
        sids = map (W.screen) (W.screens s)
        tags = map (flip W.lookupWorkspace s) sids
    when (all isJust tags) $ do
        let tags' = map (\tag -> elemIndex (fromJust tag) (map W.tag ws)) tags
        when (all isJust tags') $ do
            let sids' = map (\(S sid) -> sid) sids
                tags'' = zip sids' (map fromJust tags')
                workspaces = map snd $ sortBy (comparing fst) tags''
            setWallpaperDWorkspaces workspaces

setWallpaperDWorkspaces :: (Integral a) => [a] -> X ()
setWallpaperDWorkspaces ws = withDisplay $ \dpy -> do
    r <- asks theRoot
    a <- getAtom "OWALLPAPERD_WORKSPACES"
    c <- getAtom "CARDINAL"
    io $ changeProperty32 dpy r a c propModeReplace (map fromIntegral ws)
