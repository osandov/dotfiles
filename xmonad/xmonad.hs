import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Actions.WorkspaceNames
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
import XMonad.Prompt
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Util.WorkspaceCompare (getSortByIndex)

import qualified XMonad.StackSet as W

import Control.Monad (when)
import Data.Char (toLower)
import Data.List (elemIndex, sortBy)
import Data.Maybe (fromJust, isJust)
import Data.Monoid
import Data.Ord (comparing)
import Text.Printf (printf)

{- prompt color scheme -}
promptBgColor  = "#222222"
promptFgColor  = "#bababa"
promptBgHLight = "#005577"
promptFgHLight = "#ededed"

dzenCommand   = "dzen2 $(~/.xmonad/dzen_flags)"
conkyCommand  = "conky -c ~/.xmonad/status/conky_dzen | " ++ dzenCommand

promptFont = "-misc-fixed-medium-r-semicondensed-*-13-*-*-*-*-*-*-*"
dmenuCommand = printf "~/.dotfiles/bin/dmenu_run -fn '%s' -nb '%s' -nf '%s' -sb '%s' -sf '%s'" promptFont promptBgColor promptFgColor promptBgHLight promptFgHLight

xmonadStatus = dzenCommand ++ " -xs 1 -w 50% -ta l"
systemStatus = conkyCommand ++ " -xs 1 -x 50% -w 50% -ta r"

(/->)   :: Monoid m => Query Bool -> Query m -> Query m
p /-> f =  p >>= \b -> if b then idHook else f
infix 0 /->

followTo :: Direction1D -> WSType -> X ()
followTo dir t = doTo dir t getSortByIndex $ \w ->
    (windows (W.shift w)) >> (windows (W.greedyView w))

main = do
    dzenXmonad <- spawnPipe xmonadStatus
    dzenSystem <- spawnPipe systemStatus
    xmonad $ withUrgencyHook NoUrgencyHook $ ewmh $ defaultConfig
             { startupHook = ewmhDesktopsStartup
             , manageHook = manageSpawn <+> manageDocks <+> myManageHook
             , layoutHook = avoidStrutsOn [U] $ smartBorders $ myLayout
             , logHook    = workspaceNamesPP defaultPP
                            { ppCurrent = dzenColor "#b58900" "" . wrap "[" "]"
                            , ppUrgent  = dzenColor "#dc322f" "" . wrap "(" ")"
                            , ppTitle   = dzenColor "#268bd2" "" . shorten 70
                            , ppOrder   = reverse
                            , ppOutput  = hPutStrLn dzenXmonad
                            , ppLayout  = wrap "^i(.xmonad/icons/" ".xbm)" . (map toLower)
                            } >>= dynamicLogWithPP
                              >> fadeWindowsLogHook myFadeHook
                              >> wallpaperDLogHook
             , handleEventHook = ewmhDesktopsEventHook <+> fadeWindowsEventHook
             , normalBorderColor  = "#586e75"
             , focusedBorderColor = "#d33682"
             , modMask            = myModMask
             , terminal           = "xterm"
             , workspaces         = myWorkspaces
             } `additionalKeys` myKeys

myKeys = [ ((myModMask, xK_p), spawnHere dmenuCommand)
         , ((myModMask .|. shiftMask, xK_p), spawnHere "xterm -e python")
         , ((myModMask, xK_q), spawn
                 "xmonad --recompile && (killall conky; xmonad --restart)")
         , ((myModMask .|. shiftMask, xK_l),
                 spawn "~/.dotfiles/bin/lock_screensaver")

         , ((myModMask, xK_0), toggleWS)
         , ((myModMask, xK_o), renameWorkspace myXPConfig)
         , ((myModMask .|. shiftMask, xK_o), setCurrentWorkspaceName "")

         , ((myModMask,                 xK_minus), moveTo Next EmptyWS)
         , ((myModMask .|. shiftMask,   xK_minus), shiftTo Next EmptyWS)
         , ((myModMask .|. controlMask, xK_minus), followTo Next EmptyWS)

         , ((myModMask, xK_grave), spawn "~/.dotfiles/bin/toggle_composite")

         , ((myModMask .|. shiftMask, xK_semicolon), spawn "gvim -f")
         , ((myModMask .|. shiftMask, xK_t), sendMessage $ ToggleStrut D)

         , ((0       ,  xK_Print), spawn "xfce4-screenshooter -f")
         , ((mod1Mask,  xK_Print), spawn "xfce4-screenshooter -w")
         , ((shiftMask, xK_Print), spawn "xfce4-screenshooter -r")
         ] ++
         [ ((myModMask .|. controlMask, k), swapWithCurrent i)
           | (i, k) <- zip myWorkspaces [xK_1 ..]]

myModMask = mod4Mask

myWorkspaces = ["net"] ++ map show [2..9]

myManageHook = composeOne
               [ isFullscreen                 -?> doFullFloat
               , isDialog                     -?> doCenterFloat
               , className =? "Gnuplot"       -?> doCenterFloat
               , className =? "Xfce4-notifyd" -?> doIgnore
               , className =? "Xfrun4"        -?> doCenterFloat
               , return True                  -?> doF W.swapDown
               ]

myFadeHook = composeAll
             [ isUnfocused  --> transparency 0.1
             , isFullscreen --> opaque
             , isUnfocused  /-> opaque
             ]

myXPConfig = defaultXPConfig
    { font               = promptFont
    , bgColor            = promptBgColor
    , fgColor            = promptFgColor
    , bgHLight           = promptBgHLight
    , fgHLight           = promptFgHLight
    , height             = 15
    , promptBorderWidth  = 0
    , position           = Top
    }

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

netLayout = tab ||| tall ||| wide

myLayout = onWorkspace "net" netLayout defaultLayout

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
