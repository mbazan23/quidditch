import Jugador.*
import Escoba.*

class Equipo{
	var property rival
	var property jugadores = []
	var property puntos
	
	method tieneJugadorEstrella(){
		return jugadores.any({jugador => jugador.esEstrella(rival)})
	}
	
	method jugarConOtro(equipo){
		
	}
	
	method sumarPuntos(losPuntos){
		puntos = puntos + losPuntos
	}
	
	method tieneQuaffle(){
		jugadores.any({jugador => jugador.tieneQuaffle()})
	}
}