extends Node

# HINT: Kita simpan path gambar potret di dalam database agar gambarnya otomatis berganti
var dialogues = {
	"pertemuan_kakek_lanjung": [
		{
			"nama": "Kakek Lanjung", 
			"teks": "Ah, Gendra! Sepertinya kamu lupa akan sesuatu.", 
			"portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG,
			"event": ""
		},
		{
			"nama": "Gendra", 
			"teks": "Betul lupa sarapan, Kek. makanya tenaga jadi kurang....", 
			"portrait": ResourcePaths.PORTRAIT_GENDRA,
			"event": ""
		},
		{
			"nama": "Kakek Lanjung", 
			"teks": "hhaahh..... emang sarapan sih penting. tapi gini setiap kamu mengalahkan musuh.", 
			"portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG,
			"event": "buka_shop_skill"
		},
		{
			"nama": "Kakek Lanjung", 
			"teks": "Kamu akan dapat exp, itu bisa menambah kekuatan dan membuka skill. cek aja di menu", 
			"portrait": ResourcePaths.PORTRAIT_GRANDPA_LANJUNG,
			"event": "buka_shop_skill"
		}
	]
}
