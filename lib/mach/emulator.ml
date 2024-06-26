let mem_store_address (m: Mach.t) (o: Arm.operand) (rgs: int64 array) : int =
  match o with
  | Arm.Imm (Lit q) -> Mach.map_addr m q
  | Arm.Reg r -> Mach.map_addr m (rgs.(Mach.reg_index r))
  | Arm.Offset(Arm.Ind1(Arm.Lit i)) -> Mach.map_addr m i
  | Arm.Offset(Arm.Ind2(r)) -> Mach.map_addr m rgs.(Mach.reg_index r)
  | Arm.Offset(Arm.Ind3(r, Lit i)) -> Mach.map_addr m (Int64.add rgs.(Mach.reg_index r) i) 
  | _ -> Mach.mach_error m (Arm_stringifier.string_of_operand o) "Unexpected operand"

let store_at (bt: Mach.sbyte) (addr: int) (m: Mach.sbyte array) = Array.set m addr bt
let read_at (addr: int64) (m: Mach.sbyte array) : Mach.sbyte = Array.get m (Int64.to_int addr)

let sbytes_of_data : Arm.data -> Mach.sbyte list = function
  | Arm.Quad i -> Mach.sbytes_of_int64 i 
  | Arm.QuadArr ia -> List.flatten (List.map Mach.sbytes_of_int64 ia) 
  | Arm.Byte b -> [Mach.Byte(b |> Char.chr)]
  | Arm.ByteArr ba -> List.map (fun b -> Mach.Byte(b |> Char.chr)) ba
  | Arm.Word w -> Mach.sbytes_of_int32 w
  | Arm.WordArr wa -> List.flatten (List.map Mach.sbytes_of_int32 wa)

let data_into_memory (addr: int) (value: Arm.data) (m: Mach.sbyte array) : unit =
  let bytes = sbytes_of_data value in 
  let f (i: int) (e: Mach.sbyte) = (store_at e (addr + i) m) in 
  List.iteri f bytes

let rec read_bytes (addr: int64) (count: int64) (m: Mach.sbyte array) : Mach.sbyte list =
  match count with
  | 1L -> [read_at addr m]
  | _ ->  (read_bytes addr (Int64.sub count 1L) m) @ [read_at (Int64.add addr (Int64.sub count 1L)) m]

let data_into_reg (r: Arm.reg) (value: Arm.data) (rgs: int64 array) : unit = 
  match value with
  | Arm.Quad i -> rgs.(Mach.reg_index r) <- i 
  | Arm.Word w -> rgs.(Mach.reg_index r) <- Int64.of_int32 w 
  | Arm.Byte b -> rgs.(Mach.reg_index r) <- Int64.of_int32 (Int32.of_int (b)) 
  | _ -> failwith "Unexpected data type"

let reg_store (v: Arm.data) (r: Arm.reg) (rgs: int64 array) : unit = data_into_reg r v rgs

let mem_store (m: Mach.t) (v: Arm.data) (o: Arm.operand) (rgs: int64 array) (mem: Mach.sbyte array) : unit =
  let str_addr = (mem_store_address m o rgs) in 
  data_into_memory str_addr v mem

let step (m: Mach.t) : Mach.t = 
  let insn = Mach.get_insn m m.pc in 
  match insn with
  | (Arm.Mov, [o1; o2]) ->
    let reg = begin match o1 with
      | Arm.Reg r -> r
      | _ -> Mach.mach_error m (Arm_stringifier.string_of_operand o1) "Unexpexted register"
    end in
    let v = begin match o2 with
      | Arm.Imm (Lit i) -> i
      | Arm.Imm (Lbl l) -> Mach.lookup_label m.info.layout l
      | Arm.Reg r -> m.regs.(Mach.reg_index r) 
      | _ -> Mach.mach_error m (Arm_stringifier.string_of_operand o2) "Unexpected immediate"
    end in 
    m.regs.(Mach.reg_index reg) <- v;
    m
  | _ -> Mach.mach_error m (Arm_stringifier.string_of_insn insn) "Unexpected instruction"

let run (m: Mach.t) : unit = 
  let rec loop (m: Mach.t) : unit = 
    let m' = step m in 
    m'.pc <- (Int64.add m'.pc 8L);
    if m'.pc = m'.info.exit_val || m'.regs.(Mach.reg_index Arm.SP) = m'.info.exit_val then () else
    loop m'
  in loop m 

