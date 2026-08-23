import {mkdtemp, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import type {TruncationResult} from '@earendil-works/pi-coding-agent'
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
} from '@earendil-works/pi-coding-agent'

export interface TruncatedOutput {
	text: string
	truncation?: TruncationResult
	fullOutputPath?: string
}

/**
 * Truncate tool output to the agent's default limits; when anything is cut,
 * keep the complete output in a private temp file the model can read later.
 * `truncation` and `fullOutputPath` are only set when truncation happened.
 */
export async function saveTruncatedOutput(
	output: string,
	tempPrefix: string,
	fileName: string,
): Promise<TruncatedOutput> {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	})

	if (!truncation.truncated) {
		return {text: truncation.content}
	}

	// mkdtemp yields a directory nobody else knows about, so the file needs no
	// mutation queue; mode 0600 keeps API responses private on shared machines.
	const tempFile = join(await mkdtemp(join(tmpdir(), tempPrefix)), fileName)
	await writeFile(tempFile, output, {encoding: 'utf8', mode: 0o600})

	const omittedLines = truncation.totalLines - truncation.outputLines
	const omittedBytes = truncation.totalBytes - truncation.outputBytes
	const text =
		`${truncation.content}\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines` +
		` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).` +
		` ${omittedLines} lines (${formatSize(omittedBytes)}) omitted.` +
		` Full output saved to: ${tempFile}]`

	return {text, truncation, fullOutputPath: tempFile}
}
