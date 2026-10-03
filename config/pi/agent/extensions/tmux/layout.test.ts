import {afterEach, describe, test} from 'node:test'
import assert from 'node:assert/strict'
import {spawn} from 'node:child_process'
import {
	MIN_PANE_HEIGHT,
	MIN_PANE_WIDTH,
	OperationQueue,
	planWorkerSplit,
	type PaneInfo,
	type PanePosition,
} from './layout.ts'

interface ExecResult {
	code: number
	stdout: string
	stderr: string
}

const sessions = new Set<string>()

async function exec(command: string, args: string[]): Promise<ExecResult> {
	return new Promise((resolve, reject) => {
		const child = spawn(command, args, {stdio: ['ignore', 'pipe', 'pipe']})
		let stdout = ''
		let stderr = ''
		child.stdout.setEncoding('utf8').on('data', (data: string) => {
			stdout += data
		})
		child.stderr.setEncoding('utf8').on('data', (data: string) => {
			stderr += data
		})
		child.on('error', reject)
		child.on('close', (code) => resolve({code: code ?? 1, stdout, stderr}))
	})
}

async function tmux(...args: string[]): Promise<string> {
	const result = await exec('tmux', args)
	if (result.code !== 0) throw new Error(result.stderr)
	return result.stdout.trim()
}

async function createSession(): Promise<{name: string; paneId: string}> {
	const name = `pi-tmux-test-${process.pid}-${crypto.randomUUID()}`
	sessions.add(name)
	await tmux('new-session', '-d', '-s', name, '-x', '286', '-y', '80')
	const paneId = await tmux(
		'display-message',
		'-p',
		'-t',
		`${name}:1.1`,
		'#{pane_id}',
	)
	return {name, paneId}
}

async function destroySession(name: string): Promise<void> {
	await exec('tmux', ['kill-session', '-t', name])
	sessions.delete(name)
}

function pane(
	paneId: string,
	width: number,
	height: number,
	name = '',
): PaneInfo {
	return {
		name,
		paneId,
		alive: true,
		command: 'zsh',
		pid: '1',
		width,
		height,
	}
}

async function listPanes(session: string): Promise<PaneInfo[]> {
	const output = await tmux(
		'list-panes',
		'-t',
		`${session}:1`,
		'-F',
		'#{pane_id}\t#{@pi_name}\t#{pane_current_command}\t#{pane_pid}\t#{pane_dead}\t#{pane_width}\t#{pane_height}',
	)
	return output.split('\n').map((line) => {
		const [paneId, name, command, pid, dead, width, height] = line.split('\t')
		return {
			name,
			paneId,
			alive: dead !== '1',
			command,
			pid,
			width: Number(width),
			height: Number(height),
		}
	})
}

async function addWorker(
	queue: OperationQueue,
	session: string,
	piPaneId: string,
	name: string,
	position: PanePosition,
): Promise<string> {
	return queue.run(async () => {
		const panes = await listPanes(session)
		const piPane = panes.find(({paneId}) => paneId === piPaneId)
		if (!piPane) throw new Error('Pi pane not found')
		const plan = planWorkerSplit(
			position,
			piPane,
			panes.filter(({paneId}) => paneId !== piPaneId),
		)
		const paneId = await tmux(
			'split-window',
			'-d',
			plan.flag,
			'-P',
			'-F',
			'#{pane_id}',
			'-t',
			plan.targetPaneId,
		)
		await tmux('set-option', '-p', '-t', paneId, '@pi_name', name)
		return paneId
	})
}

afterEach(async () => {
	await Promise.all([...sessions].map(destroySession))
})

describe('unit: tmux layout planning', () => {
	const piPane = pane('%1', 286, 79)

	test('opens the first right worker beside Pi', () => {
		assert.deepEqual(planWorkerSplit('right', piPane, []), {
			flag: '-h',
			targetPaneId: '%1',
		})
	})

	test('ignores unmanaged panes when opening the first worker', () => {
		assert.deepEqual(planWorkerSplit('right', piPane, [pane('%2', 142, 79)]), {
			flag: '-h',
			targetPaneId: '%1',
		})
	})

	test('stacks right workers by splitting the tallest pane', () => {
		assert.deepEqual(
			planWorkerSplit('right', piPane, [
				pane('%2', 142, 19, 'short'),
				pane('%3', 142, 39, 'tall'),
			]),
			{flag: '-v', targetPaneId: '%3'},
		)
	})

	test('spreads bottom workers by splitting the widest pane', () => {
		assert.deepEqual(
			planWorkerSplit('bottom', piPane, [
				pane('%2', 71, 39, 'narrow'),
				pane('%3', 142, 39, 'wide'),
			]),
			{flag: '-h', targetPaneId: '%3'},
		)
	})

	test('rejects splits below the minimum dimensions', () => {
		assert.throws(
			() => planWorkerSplit('right', pane('%1', MIN_PANE_WIDTH * 2, 79), []),
			new RegExp(`less than ${MIN_PANE_WIDTH} columns`),
		)
		assert.throws(
			() => planWorkerSplit('right', piPane, [
				pane('%2', 142, MIN_PANE_HEIGHT * 2, 'worker'),
			]),
			new RegExp(`less than ${MIN_PANE_HEIGHT} rows`),
		)
	})

	test('continues queued operations after a failure', async () => {
		const queue = new OperationQueue()
		const order: number[] = []
		const failed = queue.run(async () => {
			order.push(1)
			throw new Error('failed')
		})
		const completed = queue.run(async () => {
			order.push(2)
			return 'done'
		})
		await assert.rejects(failed, /failed/)
		assert.equal(await completed, 'done')
		assert.deepEqual(order, [1, 2])
	})
})

describe('integration: tmux layout commands', () => {
	test('keeps the Pi width after adding sequential right workers', async () => {
		const session = await createSession()
		const queue = new OperationQueue()
		for (let index = 0; index < 4; index++) {
			await addWorker(
				queue,
				session.name,
				session.paneId,
				`worker-${index}`,
				'right',
			)
		}
		const panes = await listPanes(session.name)
		const piPane = panes.find(({paneId}) => paneId === session.paneId)
		assert.equal(piPane?.width, 143)
		assert.equal(panes.filter(({name}) => name.startsWith('worker-')).length, 4)
	})

	test('rejects excess bottom workers without changing the layout', async () => {
		const session = await createSession()
		const queue = new OperationQueue()
		for (let index = 0; index < 8; index++) {
			await addWorker(
				queue,
				session.name,
				session.paneId,
				`bottom-${index}`,
				'bottom',
			)
		}
		const layout = (panes: PaneInfo[]) =>
			panes.map(({paneId, name, width, height}) => ({
				paneId,
				name,
				width,
				height,
			}))
		const before = layout(await listPanes(session.name))
		await assert.rejects(
			addWorker(
				queue,
				session.name,
				session.paneId,
				'bottom-overflow',
				'bottom',
			),
			new RegExp(`less than ${MIN_PANE_WIDTH} columns`),
		)
		assert.deepEqual(layout(await listPanes(session.name)), before)
	})
})

describe('end-to-end: concurrent worker creation', () => {
	test('creates seven right workers without collapsing Pi', async () => {
		const session = await createSession()
		const queue = new OperationQueue()
		await Promise.all(
			Array.from({length: 7}, (_, index) =>
				addWorker(
					queue,
					session.name,
					session.paneId,
					`worker-${index}`,
					'right',
				),
			),
		)

		const panes = await listPanes(session.name)
		const piPane = panes.find(({paneId}) => paneId === session.paneId)
		const workers = panes.filter(({name}) => name.startsWith('worker-'))
		assert.equal(piPane?.width, 143)
		assert.equal(workers.length, 7)
		assert.ok(
			Math.min(...workers.map(({height}) => height)) >= MIN_PANE_HEIGHT,
		)
	})
})
