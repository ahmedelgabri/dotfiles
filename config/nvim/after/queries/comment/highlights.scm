;; extends

; TODO: figure out how to make this work

; Conceal github URLs, mainly in plugins so I can still have a nice short
; visuals but can run `gx` on a plugin to visit its page. Only `https` because
; I want to see if I'm using `http` which is something I shouldn't allow for
; obvious reasons.
;
; Not Sure if I should expand the regex to only match strings only inside
; `Plug/Bundle/Plugin/call minpac#add` or keep it generic.

; syn match gitHubURL  /https\:\/\/github\.com\//  conceal containedin=luaComment,luaString
; syn match gitHubURL  /https\:\/\/github\.com\//  conceal containedin=vimString
