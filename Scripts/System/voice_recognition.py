import json
import vosk
import pyaudio
import threading
from queue import Queue

class VoiceRecognizer:
	def __init__(self):
		# Initialize Vosk model - make sure path is relative to your project
		model = vosk.Model("vosk-model-small-en-us-0.15")
		self.rec = vosk.KaldiRecognizer(model, 16000)
		
		self.audio_queue = Queue()
		self.is_listening = False
		self.latest_result = ""
		self.new_result = False
		
	def start_listening(self):
		if not self.is_listening:
			self.is_listening = True
			self.audio_thread = threading.Thread(target=self._audio_loop, daemon=True)
			self.audio_thread.start()
	
	def stop_listening(self):
		self.is_listening = False
	
	def _audio_loop(self):
		p = pyaudio.PyAudio()
		stream = p.open(
			format=pyaudio.paInt16,
			channels=1,
			rate=16000,
			input=True,
			frames_per_buffer=4000
		)
		
		while self.is_listening:
			try:
				data = stream.read(4000, exception_on_overflow=False)
				if self.rec.AcceptWaveform(data):
					result = json.loads(self.rec.Result())
					text = result.get('text', '').strip()
					if text:
						self.latest_result = text
						self.new_result = True
			except Exception as e:
				print(f"Audio processing error: {e}")
		
		stream.stop_stream()
		stream.close()
		p.terminate()
	
	def get_latest_result(self):
		if self.new_result:
			self.new_result = False
			return self.latest_result
		return None
	
	def has_new_result(self):
		return self.new_result
