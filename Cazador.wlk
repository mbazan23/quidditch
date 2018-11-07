import Jugador.*
import Pelota.*

class Cazador inherits Jugador{
	method tieneQuaffle(){
		return pelota == quaffle 
	}
	
	method noBloquean(equipoRival){
		return equipoRival.jugadores().all({jugador => not jugador.puedeBloquear(self)})
		
	}
	
	method meterGol(equipoRival){	
		if (self.noBloquean(equipoRival)){
			equipo.sumarPuntos(10)
			skills = skills +5
		}
		else {
			skills = skills - 2
		}
		pelota = null
		
	}
	override method habilidad(){
		return super() + (punteria * fuerza )
	}
	
	override method jugar(oponente){
		if (self.tieneQuaffle()){
			self.meterGol(oponente)
		}
	}
	
	override method puedeBloquear(oponente){
		return self.lePasaElTrapo(oponente)
	}
	
	method esBlancoUtil(){
		return pelota == quaffle
	}
	

}