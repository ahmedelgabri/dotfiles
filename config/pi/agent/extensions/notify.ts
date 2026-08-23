/**
 * Pi Notify Extension
 *
 * Sends a terminal notification when Pi agent is done and waiting for input.
 * Supports Unix terminal protocols:
 * - OSC 777: Ghostty, WezTerm, rxvt-unicode
 * - OSC 99: Kitty
 * - tmux passthrough for both protocols
 */

import type {ExtensionAPI} from '@earendil-works/pi-coding-agent'

function wrapForTmux(sequence: string): string {
	if (!process.env.TMUX) return sequence

	// tmux only forwards terminal-specific escape sequences inside a DCS passthrough wrapper.
	return `\x1bPtmux;${sequence.replaceAll('\x1b', '\x1b\x1b')}\x1b\\`
}

function notifyOSC777(title: string, body: string): void {
	process.stdout.write(wrapForTmux(`\x1b]777;notify;${title};${body}\x07`))
}

function notifyOSC99(title: string, body: string): void {
	// Kitty OSC 99: i=notification id, d=0 means not done yet, p=body for second part
	process.stdout.write(wrapForTmux(`\x1b]99;i=1:d=0;${title}\x1b\\`))
	process.stdout.write(wrapForTmux(`\x1b]99;i=1:p=body;${body}\x1b\\`))
}

function notify(title: string, body: string): void {
	if (process.env.KITTY_WINDOW_ID) {
		notifyOSC99(title, body)
	} else {
		notifyOSC777(title, body)
	}
}

export default function (pi: ExtensionAPI) {
	pi.on('agent_settled', () => {
		notify('Pi', 'Ready for input')
	})
}
