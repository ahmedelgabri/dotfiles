export interface PaneInfo {
	name: string
	paneId: string
	alive: boolean
	command: string
	pid: string
	width: number
	height: number
}

export type PanePosition = 'right' | 'bottom'

export interface SplitPlan {
	flag: '-h' | '-v'
	targetPaneId: string
}

export const MIN_PANE_WIDTH = 20
export const MIN_PANE_HEIGHT = 3

export class OperationQueue {
	private tail: Promise<void> = Promise.resolve()

	run<T>(operation: () => Promise<T>): Promise<T> {
		const result = this.tail.then(operation, operation)
		this.tail = result.then(
			() => undefined,
			() => undefined,
		)
		return result
	}
}

export function planWorkerSplit(
	position: PanePosition,
	piPane: PaneInfo,
	otherPanes: PaneInfo[],
): SplitPlan {
	let target: PaneInfo
	let flag: SplitPlan['flag']
	const workerPanes = otherPanes.filter(({name}) => name)

	if (workerPanes.length === 0) {
		target = piPane
		flag = position === 'right' ? '-h' : '-v'
	} else if (position === 'right') {
		target = workerPanes.reduce((largest, pane) =>
			pane.height > largest.height ? pane : largest,
		)
		flag = '-v'
	} else {
		target = workerPanes.reduce((widest, pane) =>
			pane.width > widest.width ? pane : widest,
		)
		flag = '-h'
	}

	const resultingWidth =
		flag === '-h' ? Math.floor((target.width - 1) / 2) : target.width
	const resultingHeight =
		flag === '-v' ? Math.floor((target.height - 1) / 2) : target.height
	if (resultingWidth < MIN_PANE_WIDTH) {
		throw new Error(
			`Cannot add a ${position} pane: splitting ${target.paneId} would leave less than ${MIN_PANE_WIDTH} columns per pane.`,
		)
	}
	if (resultingHeight < MIN_PANE_HEIGHT) {
		throw new Error(
			`Cannot add a ${position} pane: splitting ${target.paneId} would leave less than ${MIN_PANE_HEIGHT} rows per pane.`,
		)
	}

	return {flag, targetPaneId: target.paneId}
}
