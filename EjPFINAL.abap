*&---------------------------------------------------------------------*
*& Report Z09_EJFINAL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z09_ejfinal.

INCLUDE Z09_EJFINAL_TOP.
INCLUDE Z09_EJFINAL_F01.

START-OF-SELECTION.
PERFORM get_data.
PERFORM proces_data.
PERFORM print_data.
PERFORM guardar_log.

*&---------------------------------------------------------------------*
*& Include          Z09_EJFINAL_TOP
*&---------------------------------------------------------------------*
TABLES: ekko.
TABLES: lfa1.

SELECTION-SCREEN BEGIN OF BLOCK b1.
SELECT-OPTIONS:
p_comp FOR ekko-ebeln,
p_doc FOR ekko-bsart OBLIGATORY,
p_creat FOR ekko-ernam,
p_provee FOR ekko-lifnr,
p_pais FOR lfa1-land1.

PARAMETERS:
  p_imp            TYPE i DEFAULT 5 OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2.
PARAMETERS:
  rdb_wr  RADIOBUTTON GROUP rb1,
  rdb_alv RADIOBUTTON GROUP rb1 DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

TYPES: BEGIN OF ty_ekko,
         ebeln TYPE ekko-ebeln,
         bsart TYPE ekko-bsart,
         ernam TYPE ekko-ernam,
         lifnr TYPE ekko-lifnr,
         rlwrt TYPE ekko-rlwrt,
         waers TYPE ekko-waers,
         aedat TYPE ekko-aedat,
       END OF ty_ekko.

TYPES: BEGIN OF ty_ekpo,
         ebeln TYPE ekpo-ebeln,
         loekz TYPE ekpo-loekz,
         pstyp TYPE ekpo-pstyp,
       END OF ty_ekpo.


TYPES: BEGIN OF ty_lfa1,
         lifnr TYPE lfa1-lifnr,
         name1 TYPE lfa1-name1,
        adrnr TYPE lfa1-adrnr,
         stras TYPE lfa1-stras,
         telf1 TYPE lfa1-telf1,
       END OF ty_lfa1.

TYPES: BEGIN OF ty_t161t,
         bsart TYPE t161t-bsart,
         batxt TYPE t161t-batxt,
       END OF ty_t161t.

TYPES: BEGIN OF ty_usr,
         bname     TYPE v_usr_name-bname,
         name_text TYPE v_usr_name-name_text,
       END OF ty_usr.

TYPES: BEGIN OF ty_adr6,
         addrnumber TYPE adr6-addrnumber,
         smtp_addr  TYPE adr6-smtp_addr,
       END OF ty_adr6.


TYPES: BEGIN OF ty_final,
         ebeln         TYPE ekko-ebeln,
         clase_doc     TYPE string,
         rlwrt         TYPE char10,
         montoimp      TYPE ekko-rlwrt,
         waers         TYPE ekko-waers,
         name_text     TYPE v_usr_name-name_text,
         aedat         TYPE char50,
         cant_pos      TYPE i,
         cant_pos_borr TYPE i,
         pstyp         TYPE char20,
         estrategia    TYPE char10,
         aprobadores   TYPE char20,
         proveedor     TYPE char50,
         stras         TYPE char100,
         telf1         TYPE char30,
         email         TYPE adr6-smtp_addr,
         email_valido  TYPE char3,
         consulta      TYPE i,
       END OF ty_final.

DATA:

  p_nivel        TYPE char10,
  p_aprobadores  TYPE char20,

  l_pos          TYPE i,
  l_pos_del     TYPE i,

  p_consulta     TYPE i,

  h_datum_output TYPE char50.

DATA: lt_ekko       TYPE STANDARD TABLE OF ty_ekko,
      lw_ekko       TYPE ty_ekko,
      lt_ekpo       TYPE STANDARD TABLE OF ty_ekpo,
      lw_ekpo       TYPE ty_ekpo,
      lt_lfa1       TYPE STANDARD TABLE OF ty_lfa1,
      lw_lfa1       TYPE ty_lfa1,
      lt_t161t      TYPE STANDARD TABLE OF ty_t161t,
      lw_t161t      TYPE ty_t161t,
      lt_v_usr_name TYPE STANDARD TABLE OF ty_usr,
      lw_v_usr_name TYPE ty_usr,
      lt_adr6       TYPE STANDARD TABLE OF ty_adr6,
      lw_adr6       TYPE ty_adr6,
      lt_final      TYPE STANDARD TABLE OF ty_final,
      lw_final      TYPE ty_final.


DATA:
  ti_catalogo TYPE slis_t_fieldcat_alv,
  st_catalogo TYPE slis_fieldcat_alv,
  st_layout   TYPE slis_layout_alv,
  v_repid     LIKE sy-repid.


DATA: lw_log TYPE z09_ejfinalt,
      v_ejec TYPE i.

*&---------------------------------------------------------------------*
*& Include          Z09_EJFINAL_F01
*&---------------------------------------------------------------------*

FORM columns_create
  USING
    p_fieldname
    p_text_s
    p_text_m
    p_text_l.

  CLEAR st_catalogo.

  st_catalogo-fieldname = p_fieldname.
  st_catalogo-tabname = 'LT_FINAL'.
  st_catalogo-seltext_s = p_text_s.
  st_catalogo-seltext_m = p_text_m.
  st_catalogo-seltext_l = p_text_l.
  st_catalogo-outputlen = 15.
  st_catalogo-just      = 'L'.

  APPEND st_catalogo TO ti_catalogo.
ENDFORM.

FORM msg_error USING p_tabla.
IF p_tabla IS INITIAL AND sy-subrc <> 0.
    MESSAGE |No se pudieron cargar datos { p_tabla }| TYPE 'I'.
  ENDIF.
ENDFORM.


FORM calcular_monto USING p_monto TYPE ekko-rlwrt.

  IF p_monto >= 0 AND p_monto <= 1000.
    p_nivel = 'Nivel01'.

  ELSEIF p_monto > 1000 AND p_monto <= 5000.
    p_nivel = 'Nivel02'.

  ELSEIF p_monto > 5000 AND p_monto <= 10000.
    p_nivel = 'Nivel03'.

  ELSEIF p_monto > 10000.
    p_nivel = 'Nivel04'.
  ENDIF.

  IF p_monto < 10000.
    p_aprobadores = 'Gerentes'.
  ELSE.
    p_aprobadores = 'Directores'.
  ENDIF.
ENDFORM.


FORM get_data.
  SELECT ebeln bsart ernam lifnr rlwrt waers aedat
  FROM ekko
  INTO TABLE lt_ekko
  WHERE ebeln IN p_comp
  AND bsart IN p_doc
  AND ernam IN p_creat
  AND lifnr IN p_provee.
  PERFORM msg_error USING 'ekko'.

  SELECT ebeln loekz pstyp
  FROM ekpo
  INTO TABLE lt_ekpo
  FOR ALL ENTRIES IN lt_ekko
  WHERE ebeln = lt_ekko-ebeln.
  PERFORM msg_error USING 'ekpo'.

  SELECT lifnr name1 adrnr stras telf1
  FROM lfa1
  INTO TABLE lt_lfa1
  FOR ALL ENTRIES IN lt_ekko
  WHERE lifnr = lt_ekko-lifnr
   AND land1 IN p_pais.
  PERFORM msg_error USING 'lfa1'.

  SELECT bsart batxt
  FROM t161t
  INTO TABLE lt_t161t
  FOR ALL ENTRIES IN lt_ekko
  WHERE bsart = lt_ekko-bsart
  AND spras  = 'S'. "?
  PERFORM msg_error USING 't161t'.

  SELECT bname name_text
  FROM v_usr_name
  INTO TABLE lt_v_usr_name
  FOR ALL ENTRIES IN lt_ekko
  WHERE bname = lt_ekko-ernam.
  PERFORM msg_error USING 'v_usr_name'.

  SELECT addrnumber smtp_addr
   FROM adr6
   INTO TABLE lt_adr6
   FOR ALL ENTRIES IN lt_lfa1
   WHERE addrnumber = lt_lfa1-adrnr.
  PERFORM msg_error USING 'adr6'.
ENDFORM.

FORM proces_data.
  LOOP AT lt_ekko INTO lw_ekko.
    CLEAR: lw_final, l_pos, l_pos_del.

    lw_final-ebeln = lw_ekko-ebeln.

    READ TABLE lt_t161t INTO lw_t161t
    WITH KEY bsart = lw_ekko-bsart.
    CONCATENATE lw_ekko-bsart lw_t161t-batxt
    INTO lw_final-clase_doc
    SEPARATED BY space.

    lw_final-rlwrt = lw_ekko-rlwrt.

    lw_final-montoimp = lw_ekko-rlwrt + ( lw_ekko-rlwrt * p_imp / 100 ).

    lw_final-waers = lw_ekko-waers.

    READ TABLE lt_v_usr_name INTO lw_v_usr_name
    WITH KEY bname = lw_ekko-ernam. "?
    lw_final-name_text = lw_v_usr_name-name_text.

    CALL FUNCTION 'CONVERSION_EXIT_LDATE_OUTPUT'
      EXPORTING
        input  = lw_ekko-aedat
      IMPORTING
        output = h_datum_output.
    lw_final-aedat = h_datum_output.


    LOOP AT lt_ekpo INTO lw_ekpo
    WHERE ebeln = lw_ekko-ebeln. "?

      IF lw_ekpo-loekz = 'L'.
        l_pos_del = l_pos_del + 1.
      ELSE.
        l_pos = l_pos + 1.
      ENDIF.

    ENDLOOP.

    lw_final-cant_pos = l_pos.
    lw_final-cant_pos_borr = l_pos_del.


    READ TABLE lt_ekpo INTO lw_ekpo
    WITH KEY ebeln = lw_ekko-ebeln.
    IF lw_ekpo-pstyp = '9'.
      lw_final-pstyp = 'Servicio'.
    ELSE.
      lw_final-pstyp = 'Material'.
    ENDIF.

    PERFORM calcular_monto USING lw_ekko-rlwrt.
    lw_final-rlwrt = p_nivel.
    lw_final-aprobadores = p_aprobadores.

    READ TABLE lt_lfa1 INTO lw_lfa1
    WITH KEY lifnr = lw_ekko-lifnr.
    CONCATENATE  lw_ekko-lifnr lw_lfa1-name1
    INTO lw_final-proveedor
    SEPARATED BY space.

    READ TABLE lt_lfa1 INTO lw_lfa1
      WITH KEY lifnr = lw_ekko-lifnr.

    lw_final-stras = lw_lfa1-stras.

    TRANSLATE lw_final-stras TO UPPER CASE.

    READ TABLE lt_lfa1 INTO lw_lfa1
    WITH KEY lifnr = lw_ekko-lifnr. "?
    lw_final-telf1 = lw_lfa1-telf1.
    REPLACE '-' IN lw_final-telf1 WITH ' '.


    READ TABLE lt_adr6 INTO lw_adr6
          WITH KEY addrnumber = lw_lfa1-adrnr.

     lw_final-email = lw_adr6-smtp_addr.
     IF lw_final-email CS '@'.
       lw_final-email_valido = 'SI'.
    ELSE.
     lw_final-email_valido = 'NO'.
   ENDIF.

    p_consulta = p_consulta + 1.
    lw_final-consulta = p_consulta.


    APPEND lw_final TO lt_final.
  ENDLOOP.
ENDFORM.

FORM PRINT_DATA.

  " LA DEL MAIL NO SE RELACIONA.

IF rdb_wr = 'X'.
    IF lt_final IS INITIAL.
      WRITE: / 'No hay datos para mostrar con los filtros seleccionados.'.
    ELSE.
      FORMAT COLOR COL_HEADING.
      WRITE: / sy-uline.
      " Encabezados (ajustados para que quepan la mayoría)
      WRITE: / '|', (04) 'Cons',
               '|', (10) 'Documento',
               '|', (20) 'Clase Doc.',
               '|', (10) 'Nivel/Val',
               '|', (12) 'Monto Imp.',
               '|', (04) 'Mon',
               '|', (15) 'Usuario',
               '|', (10) 'Fecha',
               '|', (04) 'Pos',
               '|', (04) 'Bor',
               '|', (10) 'Tipo',
               '|', (15) 'Aprobadores',
               '|', (25) 'Proveedor',
               '|', (20) 'Email', '|'.
      WRITE: / sy-uline.
      FORMAT COLOR OFF.

      LOOP AT lt_final INTO lw_final.
        WRITE: / '|', (04) lw_final-consulta,
                 '|', (10) lw_final-ebeln,
                 '|', (20) lw_final-clase_doc,
                 '|', (10) lw_final-rlwrt,
                 '|', (12) lw_final-montoimp CURRENCY lw_final-waers,
                 '|', (04) lw_final-waers,
                 '|', (15) lw_final-name_text,
                 '|', (10) lw_final-aedat,
                 '|', (04) lw_final-cant_pos,
                 '|', (04) lw_final-cant_pos_borr,
                 '|', (10) lw_final-pstyp,
                 '|', (15) lw_final-aprobadores,
                 '|', (25) lw_final-proveedor,
                 '|', (20) lw_final-email, '|'.
      ENDLOOP.
      WRITE: / sy-uline.
    ENDIF.
  ENDIF.

IF rdb_alv = 'X'.
PERFORM columns_create USING 'EBELN' 'Doc.' 'Documento' 'Numero de Documento de Compra'.
PERFORM columns_create USING 'CLASE_DOC' 'Clase' 'Clase Doc.' 'Clase de Documento'.
PERFORM columns_create USING 'RLWRT' 'MONTO' 'Monto Total' 'Monto Total'.
PERFORM columns_create USING 'MONTOIMP' 'Imp.' 'Monto Imp.' 'Monto Imputado'.
PERFORM columns_create USING 'WAERS' 'Mon.' 'Moneda' 'Moneda del Documento'.
PERFORM columns_create USING 'NAME_TEXT' 'Usuario' 'Usuario' 'Nombre del Usuario'.
PERFORM columns_create USING 'AEDAT' 'Fecha' 'Fecha Mod.' 'Fecha de Modificacion'.
PERFORM columns_create USING 'CANT_POS' 'Pos.' 'Cant. Pos.' 'Cantidad de Posiciones'.
PERFORM columns_create USING 'CANT_POS_BORR' 'Borr.' 'Pos. Borr.' 'Posiciones Borradas'.
PERFORM columns_create USING 'PSTYP' 'Tipo' 'Tipo Pos.' 'Tipo de Posicion'.
PERFORM columns_create USING 'ESTRATEGIA' 'Estr.' 'Estrategia' 'Estrategia de Liberacion'.
PERFORM columns_create USING 'APROBADORES' 'Aprob.' 'Aprobadores' 'Aprobadores del Documento'.
PERFORM columns_create USING 'PROVEEDOR' 'Prov.' 'Proveedor' 'Codigo y Nombre del Proveedor'.
PERFORM columns_create USING 'STRAS' 'Dir.' 'Direccion' 'Direccion del Proveedor'.
PERFORM columns_create USING 'TELF1' 'Tel.' 'Telefono' 'Telefono del Proveedor'.
PERFORM columns_create USING 'EMAIL' 'Email' 'Email' 'Correo Electronico'.
PERFORM columns_create USING 'EMAIL_VALIDO' 'Val.' 'Email Val.' 'Email Valido'.
PERFORM columns_create USING 'EMAIL_VALIDO' 'Val.' 'Email Val.' 'Email Valido'.
PERFORM columns_create USING 'CONSULTA' 'Cons.' 'Consulta' 'Numero de Consulta'.

  CLEAR st_layout.
  st_layout-zebra = 'X'.
  st_layout-window_titlebar = TEXT-001.

  v_repid = sy-repid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = v_repid
      is_layout          = st_layout
      it_fieldcat        = ti_catalogo
    TABLES
      t_outtab           = LT_FINAL.
  ENDIF.
ENDFORM.


FORM GUARDAR_LOG.

SELECT MAX( nro )
INTO v_ejec
FROM z09_ejfinalt
WHERE reporte = sy-cprog.

lw_log-mandt = sy-mandt.
lw_log-reporte = sy-cprog.
lw_log-usuario = sy-uname.
lw_log-fecha = sy-datum.
lw_log-hora = sy-uzeit.
lw_log-registros = lines( lt_final ).
IF rdb_alv = 'X'.
  lw_log-tipo = 'ALV'.
ELSE.
  lw_log-tipo = 'WRITE'.
ENDIF.
lw_log-nro = v_ejec + 1.

INSERT z09_ejfinalt FROM lw_log.

IF sy-subrc = 0.
  COMMIT WORK.
ENDIF.

ENDFORM.