import Jugador.*

class Guardian inherits Jugador{
	
	override method habilidad(){
		return super() + reflejos + fuerza
	}
	
	override method puedeBloquear(oponente){
		return 3 == (new Range(1,3).anyOne())
	}
	
	method esBlancoUtil(){
		return not equipo.tieneQuaffle()
	}
}