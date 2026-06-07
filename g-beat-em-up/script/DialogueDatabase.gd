extends Node

# HINT: Kita simpan path gambar potret di dalam database agar gambarnya otomatis berganti
var dialogues = {
	"pertemuan_kakek_lanjung": [
		{
			"nama": "Kakek Lanjung", 
			"teks": "Ah, Gendra! Syukurlah kau selamat melewati hutan terkutuk itu.", 
			"portrait": "res://assets/img/Player/kakek_lanjung_potrait.png",
			"event": ""
		},
		{
			"nama": "Gendra", 
			"teks": "Hutan itu dipenuhi monster aneh, Kek. Tapi gerakanku jauh lebih cepat dari mereka.", 
			"portrait": "res://assets/img/Player/gendra_potrait.png",
			"event": ""
		},
		{
			"nama": "Kakek Lanjung", 
			"teks": "Bagus. Tapi musuh sejati menunggumu di utara. Kebetulan aku punya teknik pertarungan baru, mau melihatnya?", 
			"portrait": "res://assets/img/Player/kakek_lanjung_potrait.png",
			"event": "buka_shop_skill" # Ini akan memicu toko terbuka saat dialog selesai!
		}
	]
}
