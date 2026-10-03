import {closeSync, openSync, readSync} from 'node:fs'
import {homedir} from 'node:os'
import {basename, join} from 'node:path'

// Session headers are one short JSON line; the rest of a transcript can be
// many megabytes.
const HEADER_READ_BYTES = 64 * 1024

function readParentSession(path: string): string | undefined {
	const fd = openSync(path, 'r')
	try {
		const buffer = Buffer.alloc(HEADER_READ_BYTES)
		const bytes = readSync(fd, buffer, 0, buffer.length, 0)
		const firstLine = buffer.toString('utf8', 0, bytes).split('\n', 1)[0]
		const header = JSON.parse(firstLine) as {parentSession?: unknown}
		return typeof header.parentSession === 'string'
			? header.parentSession
			: undefined
	} finally {
		closeSync(fd)
	}
}

/** The current session file followed by its ancestors, newest first. */
export function sessionChain(
	currentFile: string | undefined,
	parentSession: string | undefined,
): string[] {
	const chain = currentFile ? [currentFile] : []
	let parent = parentSession
	while (parent && !chain.includes(parent)) {
		chain.push(parent)
		try {
			parent = readParentSession(parent)
		} catch {
			break
		}
	}
	return chain
}

export function formatHandoff(prompt: string, chain: string[]): string {
	if (chain.length === 0) return prompt
	const sessions = chain.map((path, index) => `${index + 1}. ${path}`)
	return `${prompt}\n\n## Session History\nPrevious sessions (most recent first):\n${sessions.join('\n')}\n\nUse \`pi --session <path>\` to review any session if needed.`
}

export function handoffDirectory(
	cwd: string,
	env: NodeJS.ProcessEnv = process.env,
): string {
	const stateHome = env.XDG_STATE_HOME || join(homedir(), '.local', 'state')
	return join(stateHome, 'pi-handoff', basename(cwd))
}
