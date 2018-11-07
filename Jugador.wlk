import Pelota.*

class Jugador {
	var property skills
	var property peso
	var property escoba
	var property manejoEscoba
	var property punteria
	var property fuerza
	var property reflejos
	var property vision
	var property equipo
	var property pelota
	var property turnos
	
	
	method manejoEscoba(){
		return skills / peso
	}
	method velocidad(){
		return escoba.velocidad() * manejoEscoba	
	}
	method habilidad() {
		return self.velocidad() + skills
	}	
	method lePasaElTrapo(otroJugador){
		return (self.habilidad() * 2 ) >= otroJugador.habilidad()
	}
	method esGroso(){
		var otrosJugadores = equipo.jugadores().filter({jugador => jugador != self})	
		return self.elMasHabilidoso(otrosJugadores) and self.elMasRapido()	
	}
	method elMasHabilidoso(otrosJugadores){
		return otrosJugadores.all( {jugador => jugador.habilidad() < self.habilidad()})
	}
	method elMasRapido(){
		return self.velocidad() > escoba.velocidadArbitraria()
	}
	method esEstrella(otroEquipo){
		var otrosJugadores = otroEquipo.jugadores()
		return otrosJugadores.all({jugador => self.lePasaElTrapo(jugador)})
	}
	
	method puedeBloquear(oponente)
	
	method jugar(oponente){
		turnos +=1
	}


}








