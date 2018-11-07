class Escoba{
	var property anioFabricacion
	var property salud
	var property velocidadArbitraria
	method velocidad()

}

object nimbus inherits Escoba {
	
	method antiguedad(){
		var fechaActual = new Date().year()
		return fechaActual - anioFabricacion
	}
	override method velocidad(){
		var fechaActual = new Date().year()
		return (80 -  self.antiguedad()) * salud 
	}
	

}

object saetaDeFuego inherits Escoba{

	override method velocidad(){
		return 100
	}
	
}