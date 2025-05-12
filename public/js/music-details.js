(() => {

const audioContext = new AudioContext();
const gainNode = audioContext.createGain();
gainNode.connect(audioContext.destination);
let playButton;
let progressBar;
let url;
let status;
let arrayBuffer;
let audioBuffer;
let source;
let startTime;
let duration;
let seeking;
let loopCheckbox;
let progressText;
let progress = 0;
let activeStop = false; // to prevent stop() from triggering 'ended' event
let cheatCount = 0;
let doCheatAfterLoading = false;
let volumeRange;

function cors(url) {
	return `https://corsproxy.io/?url=${url}`;
}

async function fetchWithProgress(url, onProgress) {
	const response = await fetch(url);
	const size = Number(response.headers.get('Content-Length'));
	const reader = response.body.getReader();
	let receivedLength = 0;
	const chunks = [];
	while (true) {
		const { done, value } = await reader.read();
		if (done) {
			break;
		}
		chunks.push(value);
		receivedLength += value.length;
		onProgress(receivedLength, size);
	}
	const buffer = new Uint8Array(receivedLength);
	let position = 0;
	for (let chunk of chunks) {
		buffer.set(chunk, position);
		position += chunk.length;
	}
	return buffer.buffer;
}

async function load() {
	status = 'loading';
	arrayBuffer = await fetchWithProgress(cors(url), (receivedLength, size) => {
		const progress = receivedLength / size;
		playButton.style.setProperty('--download', `${progress*360}deg`);
	});
	if (doCheatAfterLoading) {
		doCheatAfterLoading = false;
		doCheat();
	}
	audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
	duration = audioBuffer.duration;
	status = 'stopped';
}

async function playOrStop() {
	if (status === 'playing') {
		status = 'stopped';
		stop();
		playButton.classList.remove('playing');
		return;
	}

	if (status === 'loading') {
		return;
	}
	if (!audioBuffer) {
		await load();
	}

	status = 'playing';
	if (!seeking) {
		play();
	}
}

function play() {
	playButton.classList.add('playing');
	source = audioContext.createBufferSource();
	source.buffer = audioBuffer;
	source.connect(gainNode);
	source.start(0, progress * duration);
	source.loop = loopCheckbox.checked;
	source.addEventListener('ended', () => {
		source = null;
		if (activeStop) {
			activeStop = false;
			return;
		}
		progress = 0;
		playButton.classList.remove('playing');
		status = 'stopped';
	});
	startTime = audioContext.currentTime - progress * duration;
}

function stop() {
	activeStop = true;
	source?.stop();
	source?.disconnect();
}

function timeOf(progress) {
	const time = progress * duration;
	const minutes = Math.floor(time / 60);
	const seconds = String(Math.floor(time % 60)).padStart(2, '0');
	const milliseconds = String(Math.floor((time % 1) * 1000)).padStart(3, '0');
	return `${minutes}:${seconds}.${milliseconds}`;
}

function update() {
	if (source) {
		progress = (audioContext.currentTime - startTime) / duration;
		progress -= Math.floor(progress);
	}
	progressBar.style.setProperty('--progress', `${progress * 100}%`);
	if (duration) {
		progressText.textContent = `${timeOf(progress)} / ${timeOf(1)}`;
	}
	requestAnimationFrame(update);
}

function progressOf(pointerEvent) {
	const {x: rectX, width} = progressBar.getBoundingClientRect();
	const progress = (pointerEvent.clientX - rectX) / width;
	if (progress < 0) {
		return 0;
	} else if (progress > 1) {
		return 1;
	}
	return progress;
}

function startSeeking(pointerEvent) {
	pointerEvent.preventDefault();
	seeking = pointerEvent.pointerId;
	if (status === 'playing') {
		stop();
	}
}

function updateSeeking(pointerEvent) {
	if (!seeking) {
		return;
	}
	pointerEvent.preventDefault();
	progress = progressOf(pointerEvent);
}

function stopSeeking(pointerEvent) {
	if (!seeking) {
		return;
	}
	pointerEvent.preventDefault();
	seeking = null;
	if (status === 'playing') {
		play();
	}
}

function cheat(mod) {
	if (cheatCount % 2 === mod) {
		cheatCount++;
	} else {
		cheatCount = 0;
	}
	if (cheatCount !== 8) {
		return;
	}
	cheatCount = 0;
	if (arrayBuffer) {
		doCheat();
	} else {
		doCheatAfterLoading = true;
		if (status !== 'loading') {
			load();
		}
	}
}

function doCheat() {
	const a = document.createElement('a');
	a.style.display = 'none';
	a.href = URL.createObjectURL(new Blob([arrayBuffer]));
	a.download = 'bgm.ogg';
	document.body.appendChild(a);
	a.click();
	setTimeout(() => {
		URL.revokeObjectURL(a.href);
		a.remove()
	}, 0);
}

window.addEventListener('DOMContentLoaded', () => {
	playButton = document.getElementById('play-button');
	progressBar = document.getElementById('progress-bar');
	loopCheckbox = document.getElementById('loop-checkbox');
	progressText = document.getElementById('progress-text');
	volumeRange = document.getElementById('volume-range');
	url = document.getElementById('bgm').dataset.url;
	status = 'stopped';

	loopCheckbox.addEventListener('change', () => {
		if (source) {
			source.loop = loopCheckbox.checked;
		}
	});
	volumeRange.addEventListener('input', () => {
		gainNode.gain.value = volumeRange.value;
	});
	playButton.addEventListener('click', () => playOrStop());
	progressBar.addEventListener('pointerdown', startSeeking);
	window.addEventListener('pointermove', updateSeeking);
	window.addEventListener('pointerup', stopSeeking);
	update();

	loopCheckbox.addEventListener('click', () => cheat(0));
	document.getElementById('title').addEventListener('click', () => cheat(1));
});

})();
