import Jugador.*
class Golpeador inherits Jugador{
	
	override method habilidad(){
		return super() + punteria + fuerza
	}
	
	override method puedeBloquear(oponente){
		return self.esGroso()
	}
	
	method esBlancoUtil(){
		return false
	}
	override method jugar(equipoRival){
		
	}
}