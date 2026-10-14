/**
 * Variables that tie a process to a multiplexer pane. A process without a
 * terminal, such as a loop run or a test's Pi, must not inherit them; with
 * them, pane-aware extensions would act on someone else's pane: split it,
 * report agent state for it, or write to it.
 */
export const PANE_IDENTITY_VARIABLES = [
	'TMUX',
	'TMUX_PANE',
	'REX_SESSION',
	'REX_BLOCK',
]

export function withoutPaneIdentity(env: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
	const result = {...env}
	for (const name of PANE_IDENTITY_VARIABLES) delete result[name]
	return result
}
