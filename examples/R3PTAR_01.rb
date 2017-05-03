# A translation of R3PTAR_01.ev3j (JSON) to a Ruby DSL
# by Martin Vidner

comment "Connect your EV3 Brick and tap the download and run button " \
        "in the upper right corner to run the program.",
        color: "yellow",
        w: 444, h: 284, x0: 0, y0: 150
comment "You can change how far R3PTAR slithers " \
        "by changing the Count input on the Loop block.",
        color: "yellow",
        w: 444, h:284, x0: 470, y0: 150

sequence(id: "seq8", x0: 0, y0: -276) do
  start id: "8"
  large_motor :portB, power: 75.0, id: "13"
  loop_count(3, htop: 106.0, hbot: 322.0, w: 944.0, id: "15") do
    entry(id: "seq21") do
      medium_motor :portA, power:  10.0, brake: false, duration: 1.0, id: "27"
      medium_motor :portA, power: -10.0, brake: false, duration: 1.0, id: "30"
    end
    exit_from "seq21"
  end
end
