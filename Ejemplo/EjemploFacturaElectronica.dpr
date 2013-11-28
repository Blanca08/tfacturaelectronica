(******************************************************************************
 PROYECTO FACTURACION ELECTRONICA
 Copyright (C) 2010-2012 - Bambu Code SA de CV - Ing. Luis Carrasco

 Proyecto de consola que genera una Factura Electronica de ejemplo

 Este archivo pertenece al proyecto de codigo abierto de Bambu Code:
 http://bambucode.com/codigoabierto

 Cambios para CFDI v3.2 Por Ing. Pablo Torres TecSisNet.net Cd. Juarez Chihuahua
 el 11-24-2013

 La licencia de este codigo fuente se encuentra en:
 http://github.com/bambucode/tfacturaelectronica/blob/master/LICENCIA
 ******************************************************************************)
program EjemploFacturaElectronica;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ActiveX,
  ShlObj,
  Forms,
  ExtCtrls,
  ClaseOpenSSL in '..\ClaseOpenSSL.pas',
  ComprobanteFiscal in '..\ComprobanteFiscal.pas',
  FacturaElectronica in '..\FacturaElectronica.pas',
  FacturaReglamentacion in '..\FacturaReglamentacion.pas',
  FacturaTipos in '..\FacturaTipos.pas',
  libeay32 in '..\libeay32.pas',
  LibEay32Plus in '..\LibEay32Plus.pas',
  OpenSSLUtils in '..\OpenSSLUtils.pas',
  SelloDigital in '..\SelloDigital.pas',
  DateUtils,
  DocComprobanteFiscal in '..\DocComprobanteFiscal.pas',
  CadenaOriginal in '..\CadenaOriginal.pas',
  FeCFDv22 in '..\CFD\FeCFDv22.pas',
  FeCFDv2 in '..\CFD\FeCFDv2.pas' {/,},
  FeCFDv32 in '..\CFD\FeCFDv32.pas',
  FETimbreFiscalDigital in '..\CFD\FETimbreFiscalDigital.pas',
  ProveedorAutorizadoCertificacion in '..\PACs\ProveedorAutorizadoCertificacion.pas',
  FeCFD in '..\CFD\FeCFD.pas',
  EcodexWsTimbrado in '..\PACs\Ecodex\EcodexWsTimbrado.pas',
  EcodexWsSeguridad in '..\PACs\Ecodex\EcodexWsSeguridad.pas',
  PAC.Ecodex.ManejadorDeSesion in '..\PACs\Ecodex\PAC.Ecodex.ManejadorDeSesion.pas',
  FacturacionHashes in '..\FacturacionHashes.pas',
  PACEcodex in '..\PACs\Ecodex\PACEcodex.pas',
  PACComercioDigital in '..\PACs\ComercioDigital\PACComercioDigital.pas';

var
   ProveedorTimbrado : TProveedorAutorizadoCertificacion;
   TimbreDeFactura : TFETimbre;
   Timbre : UTF8String;
   sCBB, archivoFacturaXML, STimbre: String;
   Factura: TFacturaElectronica;
   Emisor, Receptor: TFEContribuyente;
   Certificado: TFECertificado;
   BloqueFolios: TFEBloqueFolios;
   Impuesto1, Impuesto2: TFEImpuestoTrasladado;
   Concepto1, Concepto2 : TFEConcepto;
   CredencialesPAC: TFEPACCredenciales;

   function GetDesktopFolder: string;
   var
     buf: array[0..255] of char;
     pidList: PItemIDList;
   begin
     Result := 'No Desktop Folder found.';
     SHGetSpecialFolderLocation(Application.Handle, CSIDL_DESKTOP, pidList);
     if (pidList <> nil) then
      if (SHGetPathFromIDList(pidList, buf)) then
        Result := buf;
   end;

begin
  {$IF CompilerVersion < 20}
      // Bajo Delphi < 2009 tenemos que mandar llamar la siguiente rutina
      // para poder usar rutinas de la clase ActiveX, en este caso la rutina
      // para obtener la ruta al Escritorio de Windows.
      CoInitialize(nil);
  {$IFEND}

  try
      // 1. Definimos los datos del emisor y receptor
      Emisor.RFC:='AAA010101AAA';
      Emisor.Nombre:='Mi Empresa SA de CV';
      Emisor.Direccion.Calle:='Calle de la Amargura';
      Emisor.Direccion.NoExterior:='123';
      Emisor.Direccion.NoInterior:='456';
      Emisor.Direccion.CodigoPostal:='87345';
      Emisor.Direccion.Colonia:='Col. Bondojito';
      Emisor.Direccion.Municipio:='Oaxaca';
      Emisor.Direccion.Estado:='Oaxaca';
      Emisor.Direccion.Pais:='M�xico';
      Emisor.Direccion.Localidad:='Oaxaca';
      //Emisor.Direccion.Referencia:='ZZZ';

       // 2. Agregamos los r�gimenes fiscales (requerido en el CFD 2.2)
      SetLength(Emisor.Regimenes, 1);
      Emisor.Regimenes[0] := 'Regimen General de Ley';

      // Asignamos los valores iguales a la direcion del emisor suponiendo que se genera en el mismo lugar que se emitio
      Emisor.ExpedidoEn.Calle:=Emisor.Direccion.Calle;
      Emisor.ExpedidoEn.NoExterior:=Emisor.Direccion.NoExterior;
      Emisor.ExpedidoEn.NoInterior:=Emisor.Direccion.NoInterior;
      Emisor.ExpedidoEn.CodigoPostal:=Emisor.Direccion.CodigoPostal;
      Emisor.ExpedidoEn.Colonia:=Emisor.Direccion.Colonia;
      Emisor.ExpedidoEn.Municipio:=Emisor.Direccion.Municipio;
      Emisor.ExpedidoEn.Estado:=Emisor.Direccion.Estado;
      Emisor.ExpedidoEn.Pais:=Emisor.Direccion.Pais;
      Emisor.ExpedidoEn.Localidad:=Emisor.Direccion.Localidad;
      Emisor.ExpedidoEn.Referencia:=Emisor.Direccion.Referencia;

      Receptor.RFC:='PWD090210DR5';
      Receptor.Nombre:='Mi Cliente SA de CV';
      Receptor.Direccion.Calle:='Patriotismo';
      Receptor.Direccion.NoExterior:='4579';
      Receptor.Direccion.NoInterior:='94';
      Receptor.Direccion.CodigoPostal:='75489';
      Receptor.Direccion.Colonia:='La A�oranza';
      //Receptor.Direccion.Municipio:='Coyoac�n';
      Receptor.Direccion.Estado:='Veracruz';
      Receptor.Direccion.Pais:='M�xico';
      Receptor.Direccion.Localidad:='Boca del Rio';
      //Receptor.Direccion.Referencia:='IZQ';

      // 3. Definimos los datos de los folios que nos autorizo el SAT (para CFD 2.2)
      {BloqueFolios.NumeroAprobacion:=1;
      BloqueFolios.AnoAprobacion:=2010;
      BloqueFolios.Serie:='A';
      BloqueFolios.FolioInicial:=1;
      BloqueFolios.FolioFinal:=1000; }

      // 4. Definimos el certificado junto con su llave privada
      Certificado.Ruta:=ExtractFilePath(Application.ExeName) + '\aaa010101aaa_CSD_01.cer';
      Certificado.LlavePrivada.Ruta:=ExtractFilePath(Application.ExeName) + '\aaa010101aaa_CSD_01.key';
      Certificado.LlavePrivada.Clave:='12345678a';

      // 5. Creamos la clase Factura con los parametros minimos.
      WriteLn('Generando factura CFD ...');
      Factura:=TFacturaElectronica.Create(Emisor, Receptor, BloqueFolios, Certificado, tcIngreso);

      //Factura.AutoAsignarFechaGeneracion := False;
      //Factura.FechaGeneracion := EncodeDateTime(2012, 05, 12, 19, 47, 22, 0);
      //Factura.OnComprobanteGenerado:=onComprobanteGenerado;
      Factura.MetodoDePago:='Tarjeta de credito';
      //Factura.NumeroDeCuenta:='1234';
      // Asignamos el lugar de expedici�n (requerido en la CFD 2.2)
      Factura.LugarDeExpedicion:='Queretaro, Qro';

      // Definimos todos los conceptos que incluyo la factura
      Concepto1.Cantidad:=10.25;
      Concepto1.Unidad:='Kilo';
      Concepto1.Descripcion:='Arroz blanco precocido';
      Concepto1.ValorUnitario:=12.23;
      Factura.AgregarConcepto(Concepto1);

      // Agregamos el impuesto del concepto 1
      Impuesto1.Nombre:='IVA';
      Impuesto1.Tasa:=16;
      Impuesto1.Importe:=(Concepto1.ValorUnitario * Concepto1.Cantidad) * (Impuesto1.Tasa/100);
      Factura.AgregarImpuestoTrasladado(Impuesto1);

      Concepto2.Cantidad:=5;
      Concepto2.Unidad:='PZA';
      Concepto2.Descripcion:='Pi�a dulce del bajio';
      Concepto2.ValorUnitario:=18.90;
      Factura.AgregarConcepto(Concepto2);

      // Agregamos el impuesto del concepto 2 con Tasa Cero
      {Impuesto2.Nombre:='IVA';
      Impuesto2.Tasa:=16;
      Impuesto2.Importe:=(Concepto2.ValorUnitario * Concepto2.Cantidad) * (Impuesto2.Tasa/100);
      Factura.AgregarImpuestoTrasladado(Impuesto2);}

      // Le damos un descuento
      //Factura.AsignarDescuento(5, 'Por pronto pago');

      // Mandamos generar la factura con el siguiente folio disponible
      if Not(DirectoryExists(GetDesktopFolder() + '\Prueba-CFDI')) then
        CreateDir(GetDesktopFolder() + '\Prueba-CFDI');

      archivoFacturaXML:=GetDesktopFolder() + '\Prueba-CFDI\MiFactura.xml';

      // Mandamos generar el CFD antes de timbrarlo
      Factura.Generar(12345, fpUnaSolaExhibicion);
      Factura.Guardar(archivoFacturaXML);

      WriteLn('Mandando a PAC para timbrado...');
      // Ya que tenemos el comprobante, lo mandamos timbrar con el PAC de nuestra elecci�n,
      // por cuestiones de ejemplo, usaremos al PAC "Comercio Digital"
      ProveedorTimbrado := TPACComercioDigital.Create;
      //ProveedorTimbrado := TPACEcodex.Create;

      try
        // Asignamos nuestras credenciales de acceso con el PAC
        CredencialesPAC.RFC   := 'AAA010101AAA';
        CredencialesPAC.Clave := 'PWD';
        CredencialesPAC.DistribuidorID := '2b3a8764-d586-4543-9b7e-82834443f219';
        ProveedorTimbrado.AsignarCredenciales(CredencialesPAC);

        // Mandamos realizar el timbrado
        TimbreDeFactura := ProveedorTimbrado.TimbrarDocumento(Factura.XML);

        // Asignamos el timbre a la factura para que sea v�lida
        WriteLn('Asignando timbre a factura para generar CFDI');
        Factura.AsignarTimbre(TimbreDeFactura);
      finally
        ProveedorTimbrado.Free;
      end;

      // Finalmente ya que la factura fue timbrada mandamos guardar la factura
      Factura.Guardar(archivoFacturaXML);

      // Para la representaci�n gr�fica debemos generar el Codigo de Barras Bidimensional (CBB)
      // TODO: Implementar generacion de CBB con libreria que no dependa de Google Charts.

      WriteLn('CFDI generado con �xito en ' + archivoFacturaXML + '. Presiona cualquier tecla para salir');
      Readln;
      FreeAndNil(Factura);
  except
    on E: Exception do
    begin
      WriteLn('Ocurrio un error:');
      Writeln(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;

  {$IF CompilerVersion < 20}
      CoUnInitialize; // Liberamos la memoria usada por la unidad ActiveX
  {$IFEND}

end.



