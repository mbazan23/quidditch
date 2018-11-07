import Jugador.*
import Pelota.*
class Buscador inherits Jugador{
	
	var property kilometros
	
	override method habilidad(){ 
		return super() + reflejos + vision
	}
	
    override method puedeBloquear(oponente){
		return false  
	}
	
	override method turnos(){
		return 1
	}
	
	method buscandoSnitch(){
		var random = new Range(1, 1000).anyOne() 
		return random < (self.habilidad() + turnos)
	}
	method nuevoturno(){
		kilometros += self.velocidad() / 1.6
	}
	override method jugar(equipoRival){
		super(equipoRival)
		self.nuevoturno()
		if (self.atrapoSnitch()){
			skills += 10
			equipo.sumarPuntos(150)
		}
	}
	
   method atrapoSnitch(){
   		return kilometros >= 5000
   }
   
   	method esBlancoUtil(){
		return (self.buscandoSnitch() or kilometros < 1000 )
	}
	
}