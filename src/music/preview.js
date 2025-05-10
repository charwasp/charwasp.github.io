const audioContext = new AudioContext();
const audioBuffers = {}
const playing = {element: null, url: null, source: null, startTime: 0, duration: 0, status: 'stopped'};

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

async function play(element, globalButton) {
	const url = element.dataset.url;

	if (playing.status === 'playing') {
		playing.source.stop();
		playing.source.disconnect();
		playing.element.style.setProperty('--progress', '0deg');
		playing.element.classList.remove('playing');
		globalButton.classList.remove('playing');
		if (url === playing.url) {
			playing.source = null;
			playing.element = null;
			playing.status = 'stopped';
			return;
		}
	}

	// The user is impatient and clicked the button again before the sound was loaded.
	if (playing.status === 'loading' && url === playing.url) {
		return;
	}

	playing.url = url;
	if (!audioBuffers[url]) {
		playing.status = 'loading';
		const arrayBuffer = await fetchWithProgress(cors(url), (receivedLength, size) => {
			const progress = receivedLength / size;
			element.style.setProperty('--download', `${progress*360}deg`);
		});
		audioBuffers[url] = await audioContext.decodeAudioData(arrayBuffer);
		// The user may want to play a different sound while this one is loading.
		if ((playing.status === 'loading' || playing.status === 'playing') && url !== playing.url) {
			return;
		}
	}

	element.classList.add('playing');
	globalButton.classList.add('playing');
	const source = audioContext.createBufferSource();
	source.loop = true;
	source.buffer = audioBuffers[url];
	source.connect(audioContext.destination);
	source.start();

	playing.status = 'playing';
	playing.element = element;
	playing.source = source;
	playing.startTime = audioContext.currentTime;
	playing.duration = audioBuffers[url].duration;
}

function updateProgress() {
	if (playing.status === 'playing') {
		let progress = (audioContext.currentTime - playing.startTime) / playing.duration;
		progress -= Math.floor(progress);
		playing.element.style.setProperty('--progress', `${progress*360}deg`);
	}
	requestAnimationFrame(updateProgress);
}

window.addEventListener('DOMContentLoaded', () => {
	const globalButton = document.getElementById('global-preview-button');
	globalButton.addEventListener('click', event => {
		if (playing.status !== 'playing') {
			return;
		}
		playing.source.stop();
		playing.source.disconnect();
		playing.element.style.setProperty('--progress', '0deg');
		playing.element.classList.remove('playing');
		globalButton.classList.remove('playing');
		playing.source = null;
		playing.element = null;
		playing.status = 'stopped';
	});

	for (const button of document.getElementsByClassName('preview-button')) {
		button.addEventListener('click', event => {
			play(event.target, globalButton);
		});
	}

	updateProgress();
});
