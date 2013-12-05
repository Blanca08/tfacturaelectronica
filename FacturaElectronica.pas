{* *****************************************************************************
  PROYECTO FACTURACION ELECTRONICA
  Copyright (C) 2010-2014 - Bambu Code SA de CV

  Esta clase representa un Comprobante Fiscal Digital en su Version 2.0 asi como
  los metodos para generarla.

  Este archivo pertenece al proyecto de codigo abierto de Bambu Code:
  http://bambucode.com/codigoabierto

  La licencia de este codigo fuente se encuentra en:
  http://github.com/bambucode/tfacturaelectronica/blob/master/LICENCIA

  Cambios para CFDI v3.2 Por Ing. Pablo Torres TecSisNet.net Cd. Juarez Chihuahua
  el 11-24-2013
***************************************************************************** *}

unit FacturaElectronica;

interface

uses FacturaTipos, ComprobanteFiscal;

type

TOnComprobanteGenerado = procedure(Sender: TObject) of Object;

///<summary>Representa una factura electronica sus metodos para generarla, leerla y validarla
/// cumpliendo la ley del Codigo Fiscal de la Federacion (CFF) Articulos 29 y 29-A.
/// (Soporta la version 2.0/2.2/3.2 de CFD)</summary>
TFacturaElectronica = class(TFEComprobanteFiscal)
{$IFDEF VERSION_DE_PRUEBA}
  public
{$ELSE}
  private
{$ENDIF}
  fComprobanteGenerado : Boolean;
  fOnComprobanteGenerado: TOnComprobanteGenerado;
  function obtenerCertificado() : TFECertificado;
public
  property FechaGeneracion;
  property FacturaGenerada;
  property Folio;
  property SubTotal;
  property Conceptos;
  property ImpuestosRetenidos;
  property ImpuestosTrasladados;
public
  /// <summary>Evento que es llamado inemdiatamente despu�s de que el CFD fue generado,
  /// el cual puede ser usado para registrar en su sistema contable el registro de la factura
  // el cual es un requisito del SAT (Art 29, Fraccion VI)</summary>
  property OnComprobanteGenerado : TOnComprobanteGenerado read fOnComprobanteGenerado write fOnComprobanteGenerado;

  constructor Create(cEmisor, cCliente: TFEContribuyente; bfBloqueFolios: TFEBloqueFolios;
                     cerCertificado: TFECertificado; tcTipo: TFETipoComprobante);  overload; deprecated;
  constructor Create(cEmisor, cCliente: TFEContribuyente; cerCertificado: TFECertificado;
                      tcTipo: TFETipoComprobante);  overload;

  destructor Destroy; override;
  /// <summary>Genera el archivo XML de la factura electr�nica con el sello, certificado, etc</summary>
  /// <param name="Folio">Este es el numero de folio que tendr� esta factura. Si
  /// es la primer factura, deber� iniciar con el n�mero 1 (Art. 29 Fraccion III)</param>
  /// <param name="fpFormaDePago">Forma de pago de la factura (Una sola exhibici�n o parcialidades)</param>
  /// <param name="sArchivo">Nombre del archivo junto con la ruta en la que se guardar� el archivo XML</param>
  procedure GenerarYGuardar(iFolio: Integer; fpFormaDePago: TFEFormaDePago; sArchivo: String); deprecated;
  procedure Generar(const aFolio: Integer; aFormaDePago: TFEFormaDePago);
  procedure Guardar(const aArchivoDestino: String);
published
  constructor Create; overload;
end;

implementation

uses sysutils, Classes;

constructor TFacturaElectronica.Create;
begin
  inherited Create;
end;

constructor TFacturaElectronica.Create(cEmisor, cCliente: TFEContribuyente; cerCertificado: TFECertificado;
                      tcTipo: TFETipoComprobante);
begin
  // Si usamos este constructor que no usa bloque de folios creamos un CFDI 3.2 por default
  inherited Create(fev32);
  // Llenamos las variables internas con las de los parametros
  inherited Emisor:=cEmisor;
  inherited Receptor:=cCliente;

  // REWRITE: Validamos aqui que el certificado sea valido
  inherited Certificado:=cerCertificado;
  inherited Tipo:=tcTipo;
end;

constructor TFacturaElectronica.Create(cEmisor, cCliente: TFEContribuyente;
            bfBloqueFolios: TFEBloqueFolios; cerCertificado: TFECertificado; tcTipo: TFETipoComprobante);
begin
    // Si usamos este metodo que usa bloque de folios creamos por default un CFD 2.2
    inherited Create(fev22);
    // Llenamos las variables internas con las de los parametros
    inherited Emisor:=cEmisor;
    inherited Receptor:=cCliente;

    // REWRITE: Validamos aqui el bloque de folios que sea valido
    inherited BloqueFolios:=bfBloqueFolios;
    // REWRITE: Validamos aqui que el certificado sea valido
    inherited Certificado:=cerCertificado;
    inherited Tipo:=tcTipo;
end;

destructor TFacturaElectronica.Destroy();
begin
   inherited Destroy;
end;

// Obtenemos el certificado de la clase padre para obtener el record
// con los datos de serie, no aprobacion, etc.
function TFacturaElectronica.obtenerCertificado() : TFECertificado;
begin
    Result:=inherited Certificado;
end;

procedure TFacturaElectronica.Generar(const aFolio: Integer; aFormaDePago: TFEFormaDePago);
begin
  if (inherited Receptor.RFC = '') then
      Raise Exception.Create('No hay un receptor configurado');

   // Especificamos los campos del CFD en el orden especifico
   // ya que de lo contrario no cumplir� con los requisitios del SAT
   inherited Folio:=aFolio;
   inherited FormaDePago:=aFormaDePago;

   // Generamos la factura solo en memoria
   inherited GenerarComprobante;

   fComprobanteGenerado := True;

   // Mandamos llamar el evento de que se genero la factura
   if Assigned(fOnComprobanteGenerado) then
      fOnComprobanteGenerado(Self);
end;

procedure TFacturaElectronica.Guardar(const aArchivoDestino: String);
begin
   if Not fComprobanteGenerado then
     raise Exception.Create('Es necesario se mande generar la factura antes de ser guardada');

   inherited GuardarEnArchivo(aArchivoDestino);
end;

procedure TFacturaElectronica.GenerarYGuardar(iFolio: Integer; fpFormaDePago: TFEFormaDePago; sArchivo: String);
begin
     Generar(iFolio, fpFormaDePago);
     Guardar(sArchivo);
end;


end.
