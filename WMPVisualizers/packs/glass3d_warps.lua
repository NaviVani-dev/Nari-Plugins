return function(R, Q, I, P, sin, cos, sqrt, abs, atan2, floor, cmp, even, sbyte, g)
local cb = {}
cb.c10007370 = function(p) return (p.t - 0.001) end
cb.c1000c980 = function(p) return (p.e == 0.0) and ((R(0.01) + (p.r * 0.93)) - R(0.01)) or (p.r * 0.93) end
cb.c100073c0 = function(p) return ((sin(p.x) * 0.01) + p.x) end
cb.c100073e0 = function(p) return ((sin(p.x) * 0.01) + p.y) end
cb.c10007460 = function(p) return ((R(0.01) + (sin(p.x) * 0.03)) + p.x) end
cb.c10007490 = function(p) return (((R(0.01) + sin(p.y)) * 0.03) + p.y) end
cb.c10007560 = function(p) return (p.e == 0.0) and (((R(0.01) + (sin(p.y) * 0.06)) + (p.y * 0.93)) - R(0.01)) or ((sin(p.y) * 0.06) + (p.y * 0.93)) end
cb.c100074f0 = function(p) return (p.e == 0.0) and (((R(0.01) + (sin(p.x) * 0.06)) + (p.x * 0.93)) - R(0.01)) or ((sin(p.x) * 0.06) + (p.x * 0.93)) end
cb.c10007690 = function(p) return ((sin(p.y) * 0.06) + (p.y * 0.98)) end
cb.c10007620 = function(p) return (p.e == 0.0) and (((R(0.01) + (sin(p.x) * 0.06)) + (p.x * 0.98)) - R(0.01)) or ((sin(p.x) * 0.06) + (p.x * 0.98)) end
cb.c10007700 = function(p) return (p.t - (P((1.0 - p.r)) * 0.035)) end
cb.c100076f0 = function(p) return (p.a * p.r) end
cb.c10007770 = function(p) return (((sin((p.y * p.y)) + sin(p.x)) * 0.01) + p.x) end
cb.c10007790 = function(p) return (((sin((p.y * p.y)) + sin(p.x)) * 0.01) + p.y) end
cb.c100078a0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 8
	esp = esp - 4 m[esp] = esi
	esi = m[esp+16]
	local_v = p[32] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	eax = (eax & 0xffff0000) | sw
	local_v = 68 & ((sw >> 8) & 255) z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	if not pf then goto L100078e6 end
	local_v = p[4] top = top + 1 st[top] = local_v
	eax = floor(st[top]) top = top - 1
	edx = eax < 0 and -1 or 0
	eax = eax ~ edx z = eax == 0 s = eax < 0
	eax = eax - edx z = eax == 0 s = eax < 0
	eax = eax + 1 z = eax == 0 s = eax < 0
	m[esp+16] = eax
	top = top + 1 st[top] = m[esp+16]
	st[top] = 0.01 / st[top]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.93
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	esp = esp + 8
	do return st[top] end
	::L100078e6::
	esp = esp - 4 m[esp] = 1008981770
	top = top + 1 st[top] = R(m[esp])
	local_v = p[4] top = top + 1 st[top] = local_v
	eax = floor(st[top]) top = top - 1
	edx = eax < 0 and -1 or 0
	eax = eax ~ edx z = eax == 0 s = eax < 0
	esp = esp - 4 m[esp] = 1008981770
	eax = eax - edx z = eax == 0 s = eax < 0
	eax = eax + 1 z = eax == 0 s = eax < 0
	m[esp+24] = eax
	top = top + 1 st[top] = m[esp+24]
	st[top] = 0.01 / st[top]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.93
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	m[esp+12] = st[top]
	top = top - 1
	top = top + 1 st[top] = R(m[esp])
	st[top] = m[esp+12] - st[top]
	esp = esp + 8
	esi = m[esp] esp = esp + 4
	esp = esp + 8
	do return st[top] end
	do return 0.0 end
end
cb.c10007800 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 8
	esp = esp - 4 m[esp] = esi
	esi = m[esp+16]
	local_v = p[32] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	eax = (eax & 0xffff0000) | sw
	local_v = 68 & ((sw >> 8) & 255) z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	if not pf then goto L10007844 end
	local_v = p[0] top = top + 1 st[top] = local_v
	eax = floor(st[top]) top = top - 1
	edx = eax < 0 and -1 or 0
	eax = eax ~ edx z = eax == 0 s = eax < 0
	eax = eax - edx z = eax == 0 s = eax < 0
	eax = eax + 1 z = eax == 0 s = eax < 0
	m[esp+16] = eax
	top = top + 1 st[top] = m[esp+16]
	st[top] = 0.01 / st[top]
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.93
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	esp = esp + 8
	do return st[top] end
	::L10007844::
	esp = esp - 4 m[esp] = 1008981770
	top = top + 1 st[top] = R(m[esp])
	local_v = p[0] top = top + 1 st[top] = local_v
	eax = floor(st[top]) top = top - 1
	edx = eax < 0 and -1 or 0
	eax = eax ~ edx z = eax == 0 s = eax < 0
	esp = esp - 4 m[esp] = 1008981770
	eax = eax - edx z = eax == 0 s = eax < 0
	eax = eax + 1 z = eax == 0 s = eax < 0
	m[esp+24] = eax
	top = top + 1 st[top] = m[esp+24]
	st[top] = 0.01 / st[top]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.93
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	m[esp+12] = st[top]
	top = top - 1
	top = top + 1 st[top] = R(m[esp])
	st[top] = m[esp+12] - st[top]
	esp = esp + 8
	esi = m[esp] esp = esp + 4
	esp = esp + 8
	do return st[top] end
	do return 0.0 end
end
cb.c100084c0 = function(p) return (((atan2((0.55 - (p.r * 0.5)), 1.0) * 0.16) + 1.0) * p.r) end
cb.c10008550 = function(p) return (p.t - 0.01) end
cb.c10007980 = function(p) return (p.t + 0.005) end
cb.c1000cee0 = function(p) return (p.e == 0.0) and ((R(0.01) + ((((cos((p.a * p.t)) + 1.0) * 0.05) + 0.93) * p.r)) - R(0.01)) or ((((cos((p.a * p.t)) + 1.0) * 0.05) + 0.93) * p.r) end
cb.c100079e0 = function(p) return (p.e == 0.0) and ((R(0.01) + (p.y * 0.93)) - R(0.01)) or (p.y * 0.93) end
cb.c1000cba0 = function(p) return (p.e == 0.0) and ((R(0.01) + (p.x * 0.96)) - R(0.01)) or (p.x * 0.96) end
cb.c10007ae0 = function(p) return (p.e == 0.0) and ((R(0.01) + (p.y * 0.98)) - R(0.01)) or (p.y * 0.98) end
cb.c10007a80 = function(p) return (p.e == 0.0) and ((R(0.01) + (p.x * 0.93)) - R(0.01)) or (p.x * 0.93) end
cb.c10009070 = function(p) return p.t end
cb.c10007b80 = function(p) return (p.e == 0.0) and ((R(0.01) + ((((sin((p.a * p.t)) + 1.0) * 0.03) + 0.92) * p.r)) - R(0.01)) or ((((sin((p.a * p.t)) + 1.0) * 0.03) + 0.92) * p.r) end
cb.c10007da0 = function(p) return (p.e == 0.0) and ((R(0.01) + p.t) - R(0.01)) or p.t end
cb.c10007c60 = function(p) return ((((sin((R(80.0) * p.r)) + 1.0) * 0.05) + 0.93) * p.r) end
cb.c10007cd0 = function(p) return ((((sin((p.a * p.r)) + 1.0) * 0.03) + 0.92) * p.r) end
cb.c10008ad0 = function(p) return (p.e == 0.0) and (Q() + p.t) or p.t end
cb.c10008ba0 = function(p) return (p.e == 0.0) and (Q() + ((p.a + 0.92) * p.y)) or ((p.a + 0.92) * p.y) end
cb.c10008b60 = function(p) return (p.e == 0.0) and (Q() + ((p.a + 0.92) * p.x)) or ((p.a + 0.92) * p.x) end
cb.c10008ee0 = function(p) return (p.e == 0.0) and ((Q() + (sin((p.b * p.r)) * p.a)) + p.t) or ((sin((p.b * p.r)) * p.a) + p.t) end
cb.c10008c20 = function(p) return ((((p.r - p.c) * 0.13) + 1.0) * p.r) end
cb.c10008d00 = function(p) return ((((p.r - p.c) * 0.03) + 1.0) * p.r) end
cb.c100092e0 = function(p) return (p.e == 0.0) and (Q() + ((((sin((p.a * p.t)) + 1.0) * 0.03) + 0.92) * p.r)) or ((((sin((p.a * p.t)) + 1.0) * 0.03) + 0.92) * p.r) end
cb.c10008dd0 = function(p) return (p.e == 0.0) and ((Q() + (sin(((p.b * p.r) * p.r)) * p.a)) + p.t) or ((sin(((p.b * p.r) * p.r)) * p.a) + p.t) end
cb.c10008fb0 = function(p) return ((sin((p.b * p.r)) * p.a) + p.t) end
cb.c10008f80 = function(p) return ((((sin((p.c * p.t)) + 1.0) * 0.03) + 0.92) * p.r) end
cb.c10009870 = function(p) return ((cos((p.b * p.x)) * p.c) + (p.y * 0.97)) end
cb.c10009850 = function(p) return ((sin((p.a * p.y)) * p.c) + (p.x * 0.97)) end
cb.c100098f0 = function(p) return ((cos(((p.a * p.x) / sqrt((((p.y * p.y) + (p.x * p.x)) + 0.1)))) * 0.01) + p.y) end
cb.c10009970 = function(p) return ((sin(((p.a * p.y) / sqrt((((p.x * p.x) + (p.y * p.y)) + 0.1)))) * 0.01) + p.x) end
cb.c100099b0 = function(p) return ((cos(((p.b * p.x) / sqrt((((p.y * p.y) + (p.x * p.x)) + 0.1)))) * 0.01) + p.y) end
cb.c10009a30 = function(p) return (p.y - (cos(((p.b * p.x) / sqrt((((p.x * p.x) + (p.y * p.y)) + 0.1)))) * 0.01)) end
cb.c10009ac0 = function(p) return (p.x - (sin(((p.a * p.y) / sqrt((((p.y * p.y) + (p.x * p.x)) + 0.1)))) * 0.01)) end
cb.c10009b00 = function(p) return (p.y - (cos(((p.a * p.x) / sqrt((((p.x * p.x) + (p.y * p.y)) + 0.1)))) * 0.01)) end
cb.c1000cb10 = function(p) return ((cos(((p.b * p.x) * p.x)) * 0.01) + p.y) end
cb.c10009bd0 = function(p) return ((sin(((p.a * p.y) * p.y)) * 0.01) + p.x) end
cb.c10009c40 = function(p) return ((sin(((p.a * p.x) * p.x)) * 0.01) + p.x) end
cb.c10009cb0 = function(p) return ((cos(((p.b * p.y) * p.y)) * 0.01) + p.y) end
cb.c10009d70 = function(p) return (((cos((sqrt(((p.x * p.x) + (p.y * p.y))) * p.b)) * sin((sqrt(((p.x * p.x) + (p.y * p.y))) * p.b))) * 0.02) + p.y) end
cb.c10009e00 = function(p) return (((sin((sqrt(((p.x * p.x) + (p.y * p.y))) * p.a)) * cos((sqrt(((p.x * p.x) + (p.y * p.y))) * p.a))) * 0.02) + p.x) end
cb.c1000da50 = function(p) return ((cos(((p.b * p.y) * p.x)) * 0.01) + (p.y * 0.97)) end
cb.c1000da20 = function(p) return ((sin(((p.a * p.y) * p.x)) * 0.01) + (p.x * 0.97)) end
cb.c1000daf0 = function(p) return ((cos(((p.b * p.y) * p.x)) * 0.01) + p.y) end
cb.c1000dad0 = function(p) return ((sin(((p.a * p.y) * p.x)) * 0.01) + p.x) end
cb.c1000db60 = function(p) return ((R(0.01) + p.x) - R(0.01)) end
cb.c1000db90 = function(p) return ((R(0.01) + p.y) - R(0.01)) end
cb.c1000dbf0 = function(p) return p.x end
cb.c1000dc00 = function(p) return p.y end
cb.c1000dca0 = function(p) return ((cos((p.b * p.x)) * 0.05) + p.y) end
cb.c1000ce40 = function(p) return ((sin((p.a * p.y)) * 0.05) + p.x) end
cb.c1000ce60 = function(p) return (((cos((p.b * p.x)) * 0.05) + p.y) + 0.03) end
cb.c1000dd80 = function(p) return (((cos((p.b * p.x)) * 0.01) + p.y) + 0.03) end
cb.c1000dd60 = function(p) return ((sin((p.a * p.y)) * 0.01) + (p.x * 0.98)) end
cb.c1000ddf0 = function(p) return (((cos((p.b * p.x)) * 0.05) + (p.x * 0.01)) + p.y) end
cb.c1000d220 = function(p) return ((sin((p.a * p.y)) * 0.05) + (p.x * 0.98)) end
cb.c1000df00 = function(p) return (((cos(((p.b * p.x) * p.x)) * 0.05) + (p.x * 0.01)) + p.y) end
cb.c1000ded0 = function(p) return ((sin(((p.a * p.y) * p.x)) * 0.05) + (p.x * 0.98)) end
cb.c1000dfb0 = function(p) return (((cos((((p.b * p.y) * p.y) * p.x)) * 0.05) + (p.x * 0.01)) + p.y) end
cb.c1000df80 = function(p) return ((sin((((p.a * p.y) * p.x) * p.x)) * 0.05) + (p.x * 0.98)) end
cb.c1000e050 = function(p) return (((cos(((p.b * p.y) * p.y)) * 0.05) + (p.x * 0.01)) + p.y) end
cb.c1000e030 = function(p) return ((sin(((p.a * p.x) * p.x)) * 0.05) + (p.x * 0.98)) end
cb.c1000e100 = function(p) return (((atan2((p.b * p.x), 1.0) * 0.05) + (p.x * 0.01)) + p.y) end
cb.c1000e0d0 = function(p) return ((atan2((p.a * p.y), 1.0) * 0.05) + (p.x * 0.98)) end
cb.c1000e1d0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = m[esp+4]
	local_v = p[4] top = top + 1 st[top] = local_v
	top = top + 1 st[top] = 1.4426950408889634
	st[top-1] = st[top-1] * st[top-0]
	top = top - 1
	local_v = st[top-0] top = top + 1 st[top] = local_v
	st[top] = floor(st[top] + 0.5)
	st[top], st[top-1] = st[top-1], st[top]
	st[top-0] = st[top-0] - st[top-1]
	st[top] = 2.0 ^ st[top] - 1.0
	top = top + 1 st[top] = 1.0
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = st[top] * 2.0 ^ floor(st[top-1])
	st[top-1] = st[top]
	top = top - 1
	st[top] = st[top] * 0.01
	st[top] = st[top] + 0.98
	st[top] = st[top] * p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000e200 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = m[esp+4]
	local_v = p[4] top = top + 1 st[top] = local_v
	top = top + 1 st[top] = 1.4426950408889634
	st[top-1] = st[top-1] * st[top-0]
	top = top - 1
	local_v = st[top-0] top = top + 1 st[top] = local_v
	st[top] = floor(st[top] + 0.5)
	st[top], st[top-1] = st[top-1], st[top]
	st[top-0] = st[top-0] - st[top-1]
	st[top] = 2.0 ^ st[top] - 1.0
	top = top + 1 st[top] = 1.0
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = st[top] * 2.0 ^ floor(st[top-1])
	st[top-1] = st[top]
	top = top - 1
	st[top] = st[top] * p[0]
	st[top] = st[top] * 0.01
	st[top] = st[top] + p[4]
	do return st[top] end
	do return 0.0 end
end
cb.c1000e3d0 = function(p) return (((sin((p.b * p.y)) + atan2(p.x, 1.0)) * 0.01) + (p.y * 0.97)) end
cb.c1000e350 = function(p) return (((sin((p.a * p.x)) + atan2(p.y, 1.0)) * 0.01) + (p.x * 0.97)) end
cb.c1000d3b0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 2
	eax = I(m[esp])
	esp = esp + 4
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000d3e0 end
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.92
	st[top] = st[top] * p[4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.01
	st[top-1] = st[top-1] - st[top-0]
	top = top - 1
	do return st[top] end
	::L1000d3e0::
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = st[top] * p[20]
	st[top] = cos(st[top])
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[20]
	st[top] = cos(st[top])
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = st[top] * 0.01
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.97
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000ab40 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 2
	eax = I(m[esp])
	esp = esp + 4
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000ab70 end
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.92
	st[top] = st[top] * p[0]
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.01
	st[top-1] = st[top-1] - st[top-0]
	top = top - 1
	do return st[top] end
	::L1000ab70::
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	local_v = st[top-0] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = sin(st[top])
	st[top], st[top-1] = st[top-1], st[top]
	st[top] = sin(st[top])
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = st[top] * 0.01
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.97
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000d540 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esi = m[esp+8]
	local_v = p[0] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	local_v = p[0] top = top + 1 st[top] = local_v
	eax = (eax & 0xffff0000) | sw
	eax = eax & 16640 z = eax == 0 pf = even(eax)
	if z then goto L1000d55a end
	st[top] = -st[top]
	::L1000d55a::
	local_v = p[4] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	local_v = p[4] top = top + 1 st[top] = local_v
	eax = (eax & 0xffff0000) | sw
	eax = eax & 16640 z = eax == 0 pf = even(eax)
	if z then goto L1000d571 end
	st[top] = -st[top]
	::L1000d571::
	local_v = st[top-0] top = top + 1 st[top] = local_v
	st[top-0] = st[top-0] * st[top-1]
	local_v = st[top-2] top = top + 1 st[top] = local_v
	st[top-0] = st[top-0] * st[top-3]
	esp = esp - 4 m[esp] = ecx
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = sqrt(st[top])
	st[top-2] = st[top]
	top = top - 1
	st[top-0] = st[top]
	top = top - 1
	m[esp+0] = st[top]
	top = top - 1
	top = top + 1 st[top] = R(m[esp])
	sw = cmp(st[top], 0.2)
	top = top - 1
	local_v = p[12] top = top + 1 st[top] = local_v
	esp = esp + 4
	eax = (eax & 0xffff0000) | sw
	local_v = 5 & ((sw >> 8) & 255) z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	if pf then goto L1000d5a7 end
	st[top] = st[top] + 0.0175
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000d5a7::
	st[top] = st[top] - 0.0175
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000d4b0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esi = m[esp+8]
	local_v = p[0] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	local_v = p[0] top = top + 1 st[top] = local_v
	eax = (eax & 0xffff0000) | sw
	eax = eax & 16640 z = eax == 0 pf = even(eax)
	if z then goto L1000d4ca end
	st[top] = -st[top]
	::L1000d4ca::
	local_v = p[4] top = top + 1 st[top] = local_v
	sw = cmp(st[top], 0.0)
	top = top - 1
	local_v = p[4] top = top + 1 st[top] = local_v
	eax = (eax & 0xffff0000) | sw
	eax = eax & 16640 z = eax == 0 pf = even(eax)
	if z then goto L1000d4e1 end
	st[top] = -st[top]
	::L1000d4e1::
	local_v = st[top-0] top = top + 1 st[top] = local_v
	st[top-0] = st[top-0] * st[top-1]
	local_v = st[top-2] top = top + 1 st[top] = local_v
	st[top-0] = st[top-0] * st[top-3]
	esp = esp - 4 m[esp] = ecx
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	st[top] = sqrt(st[top])
	st[top-2] = st[top]
	top = top - 1
	st[top-0] = st[top]
	top = top - 1
	m[esp+0] = st[top]
	top = top - 1
	top = top + 1 st[top] = R(m[esp])
	sw = cmp(st[top], 0.2)
	top = top - 1
	esp = esp + 4
	eax = (eax & 0xffff0000) | sw
	local_v = 5 & ((sw >> 8) & 255) z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	if pf then goto L1000d517 end
	local_v = p[8] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.93
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000d517::
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[12]
	st[top] = sin(st[top])
	st[top] = st[top] + 1.0
	st[top] = st[top] * 0.03
	st[top] = st[top] + 0.92
	st[top] = st[top] * p[8]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000ac50 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = g[0x1002cff8]
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000ac6c end
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	do return st[top] end
	::L1000ac6c::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000ac00 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1073741824
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000ac2d end
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[0]
	do return st[top] end
	::L1000ac2d::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000ad20 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = g[0x1002cff8]
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000ad32 end
	local_v = p[24] top = top + 1 st[top] = local_v
	do goto L1000ad35 end
	::L1000ad32::
	local_v = p[20] top = top + 1 st[top] = local_v
	::L1000ad35::
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000ace0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1073741824
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	local_v = eax & eax z = local_v == 0 c = false s = local_v < 0 pf = even(local_v)
	eax = m[esp+4]
	if z then goto L1000ad04 end
	local_v = p[24] top = top + 1 st[top] = local_v
	do goto L1000ad07 end
	::L1000ad04::
	local_v = p[20] top = top + 1 st[top] = local_v
	::L1000ad07::
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	do return 0.0 end
end
cb.c1000ae30 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = g[0x1002cff8]
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000ae6e end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000ae65 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000ae49 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000ae49::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	::L1000ae50::
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000ae65::
	eax = m[esp+4]
	local_v = p[24] top = top + 1 st[top] = local_v
	do goto L1000ae50 end
	::L1000ae6e::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	do return st[top] end
	do return 0.0 end
end
cb.c1000adc0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000ae10 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000ae07 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000adeb end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000adeb::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	::L1000adf2::
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000ae07::
	eax = m[esp+4]
	local_v = p[24] top = top + 1 st[top] = local_v
	do goto L1000adf2 end
	::L1000ae10::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000afb0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esi = m[esp+8]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 100.0
	eax = floor(st[top]) top = top - 1
	ecx = g[0x1002cff8]
	eax = sbyte((eax & 255))
	eax = eax & 1 z = eax == 0 pf = even(eax)
	eax = eax + eax z = eax == 0 s = eax < 0
	ecx = ecx - 0 z = ecx == 0 s = ecx < 0
	if z then goto L1000afff end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000b00a end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000afe6 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000afe6::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000afff::
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b043 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b033 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b023 end
	::L1000b00a::
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.01
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b023::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.97
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b033::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.96
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b043::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000aef0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esp = esp - 4 m[esp] = edi
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	esi = m[esp+12]
	edi = eax
	g[0x1002cff8] = edi
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 100.0
	eax = floor(st[top]) top = top - 1
	eax = sbyte((eax & 255))
	eax = eax & 1 z = eax == 0 pf = even(eax)
	ecx = edi
	eax = eax + eax z = eax == 0 s = eax < 0
	ecx = ecx - 0 z = ecx == 0 s = ecx < 0
	if z then goto L1000af57 end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000af62 end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000af3d end
	local_v = 0.0 top = top + 1 st[top] = local_v
	edi = m[esp] esp = esp + 4
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000af3d::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	edi = m[esp] esp = esp + 4
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000af57::
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000af9c end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000af8c end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000af7c end
	::L1000af62::
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	edi = m[esp] esp = esp + 4
	st[top] = sin(st[top])
	st[top] = st[top] * 0.01
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000af7c::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.98
	st[top] = st[top] * p[0]
	edi = m[esp] esp = esp + 4
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000af8c::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.96
	st[top] = st[top] * p[0]
	edi = m[esp] esp = esp + 4
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000af9c::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.94
	st[top] = st[top] * p[0]
	edi = m[esp] esp = esp + 4
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000b140 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esi = m[esp+8]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 100.0
	eax = floor(st[top]) top = top - 1
	ecx = g[0x1002cff8]
	eax = sbyte((eax & 255))
	eax = eax & 1 z = eax == 0 pf = even(eax)
	eax = eax + eax z = eax == 0 s = eax < 0
	ecx = ecx - 0 z = ecx == 0 s = ecx < 0
	if z then goto L1000b192 end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000b19d end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000b176 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b176::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * p[4]
	st[top] = st[top] * 0.0001
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b192::
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b1d9 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b1c9 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b1b9 end
	::L1000b19d::
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * p[4]
	st[top] = st[top] * 2e-05
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b1b9::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.97
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b1c9::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.96
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b1d9::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000b0c0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b127 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b109 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b0eb end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b0eb::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * p[0]
	st[top] = st[top] * 0.0001
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b109::
	eax = m[esp+4]
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * p[0]
	st[top] = st[top] * 2e-05
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b127::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.98
	st[top] = st[top] * p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000b2d0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = esi
	esi = m[esp+8]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 100.0
	eax = floor(st[top]) top = top - 1
	ecx = g[0x1002cff8]
	eax = sbyte((eax & 255))
	eax = eax & 1 z = eax == 0 pf = even(eax)
	eax = eax + eax z = eax == 0 s = eax < 0
	ecx = ecx - 0 z = ecx == 0 s = ecx < 0
	if z then goto L1000b322 end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000b32d end
	ecx = ecx - 1 z = ecx == 0 s = ecx < 0
	if z then goto L1000b306 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b306::
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * p[4]
	st[top] = st[top] * 6e-05
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b322::
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b369 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b359 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b349 end
	::L1000b32d::
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * p[4]
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b349::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.97
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b359::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.96
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	::L1000b369::
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	esi = m[esp] esp = esp + 4
	do return st[top] end
	do return 0.0 end
end
cb.c1000b250 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b2b7 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b299 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b27b end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b27b::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * p[0]
	st[top] = st[top] * 6e-05
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b299::
	eax = m[esp+4]
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * p[0]
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b2b7::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.98
	st[top] = st[top] * p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000b470 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = g[0x1002cff8]
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b4da end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b4af end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b489 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b489::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.02
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b4af::
	esp = esp - 4 m[esp] = 1017370378
	top = top + 1 st[top] = R(m[esp])
	eax = m[esp+8]
	esp = esp + 4
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b4da::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[4]
	do return st[top] end
	do return 0.0 end
end
cb.c1000b3e0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b45d end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b432 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b40b end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b40b::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.02
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b432::
	esp = esp - 4 m[esp] = 1017370378
	top = top + 1 st[top] = R(m[esp])
	eax = m[esp+8]
	esp = esp + 4
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b45d::
	eax = m[esp+4]
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] + 0.95
	st[top] = st[top] * p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000b5f0 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	eax = g[0x1002cff8]
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b65a end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b62f end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b609 end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b609::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.035
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[0] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.02
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b62f::
	esp = esp - 4 m[esp] = 1017370378
	top = top + 1 st[top] = R(m[esp])
	eax = m[esp+8]
	esp = esp + 4
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b65a::
	eax = m[esp+4]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.96
	st[top] = st[top] + p[32]
	do return st[top] end
	do return 0.0 end
end
cb.c1000b550 = function(q)
	local p = { [0] = q.x, [4] = q.y, [8] = q.r, [12] = q.t, [16] = q.a, [20] = q.b, [24] = q.c, [28] = q.d, [32] = q.e }
	local local_v
	local esp, top = 1000, 0
	local st, m = {}, {}
	local eax, ecx, edx, esi, edi = 0, 0, 0, 0, 0
	local z, c, s, pf, sw = false, false, false, false, 0
	esp = esp - 4 m[esp] = 1077936128
	top = top + 1 st[top] = R(m[esp])
	esp = esp + 4
	eax = floor(st[top]) top = top - 1
	g[0x1002cff8] = eax
	eax = eax - 0 z = eax == 0 s = eax < 0
	if z then goto L1000b5cd end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b5a2 end
	eax = eax - 1 z = eax == 0 s = eax < 0
	if z then goto L1000b57b end
	local_v = 0.0 top = top + 1 st[top] = local_v
	do return st[top] end
	::L1000b57b::
	eax = m[esp+4]
	local_v = p[20] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = sin(st[top])
	st[top] = st[top] * 0.03
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] * 0.02
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b5a2::
	esp = esp - 4 m[esp] = 1017370378
	top = top + 1 st[top] = R(m[esp])
	eax = m[esp+8]
	esp = esp + 4
	local_v = p[24] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[4]
	st[top] = cos(st[top])
	st[top] = st[top] * 0.03
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	local_v = p[16] top = top + 1 st[top] = local_v
	st[top] = st[top] * p[0]
	st[top-1] = st[top-1] + st[top-0]
	top = top - 1
	do return st[top] end
	::L1000b5cd::
	eax = m[esp+4]
	local_v = p[4] top = top + 1 st[top] = local_v
	st[top] = st[top] + 1.0
	st[top] = abs(st[top])
	local_v = p[28] top = top + 1 st[top] = local_v
	st[top] = st[top] - 0.03
	st[top-1] = st[top-1] * st[top-0]
	top = top - 1
	st[top] = st[top] + p[0]
	do return st[top] end
	do return 0.0 end
end
cb.c1000c920 = function(p) return (p.y - (cos((p.a * p.x)) * 0.01)) end
cb.c1000c9e0 = function(p) return (p.t + 0.0175) end
cb.c1000ca80 = function(p) return (((p.c + 0.92) * p.y) - (cos((p.b * p.x)) * 0.01)) end
cb.c1000ca50 = function(p) return (((p.c + 0.92) * p.x) - (sin((p.a * p.y)) * 0.01)) end
cb.c1000cc00 = function(p) return (p.e == 0.0) and ((R(0.01) + ((p.a + 0.92) * p.y)) - R(0.01)) or ((p.a + 0.92) * p.y) end
cb.c1000a4d0 = function(p) return (((cos(((p.y * p.x) * p.b)) + cos((p.x * p.b))) * 0.01) + (p.y * 0.97)) end
cb.c1000a4a0 = function(p) return (((sin(((p.a * p.y) * p.x)) + sin((p.a * p.y))) * 0.01) + (p.x * 0.97)) end
cb.c1000cd40 = function(p) return (((R(0.05) + 0.93) * p.y) - (cos((p.b * p.x)) * 0.01)) end
cb.c1000cd10 = function(p) return (((R(0.05) + 0.93) * p.x) - (sin((p.a * p.y)) * 0.01)) end
cb.c1000cdc0 = function(p) return ((((sin((p.a * p.r)) + 1.0) * 0.05) + 0.93) * p.r) end
cb.c10008aa0 = function(p) return ((sin(p.b * p.r) + 1.0) * p.a + 0.92) * p.r end
cb.c1000c900 = function(p) return p.x - sin(p.a * p.y) * 0.01 end
local effects = {}
effects[1] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c10007370
puVar4 = cb.c1000c980
uVar3 = 1
uVar2 = 1
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[2] = function(G, W)
local local_c = {}
local lVar1
W(0, 0, 0, 0, 0, 0, 0, cb.c100073c0, cb.c100073e0)
local_c[0] = 0
local_c[1] = 0xe
local_c[2] = 4
lVar1 = I(3)
G.d10028fc8 = 0
G.d10028fd0 = local_c[lVar1]
end
effects[3] = function(G, W)


W(0, 0, 0, 0, 0, 0, 0, cb.c10007460, cb.c10007490)
end
effects[4] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c10007560
puVar4 = cb.c100074f0
uVar3 = 0
uVar2 = 0
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[5] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c10007690
puVar4 = cb.c10007620
uVar3 = 0
uVar2 = 0
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[6] = function(G, W)

local fVar1, puVar8, puVar9, uVar2, uVar3, uVar4, uVar5, uVar6, uVar7
puVar9 = cb.c10007700
puVar8 = cb.c100076f0
uVar7 = 1
uVar6 = 1
uVar5 = 0
uVar4 = 0
uVar3 = 0
uVar2 = 0
fVar1 = R(0.06)
W((fVar1 + 0.95), uVar2, uVar3, uVar4, uVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[7] = function(G, W)
local local_8 = {}
local lVar1
W(0, 0, 0, 0, 0, 0, 0, cb.c10007770, cb.c10007790)
local_8[0] = 0
local_8[1] = 8
lVar1 = I(2)
G.d10028fd0 = local_8[lVar1]
end
effects[8] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c100078a0
puVar4 = cb.c10007800
uVar3 = 0
uVar2 = 0
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[9] = function(G, W)


W(0, 0, 0, 0, 0, 1, 1, cb.c100084c0, cb.c10008550)
end
effects[10] = function(G, W)

local fVar1, fVar6, lVar2, puVar10, puVar9, uVar3, uVar4, uVar5, uVar7, uVar8
puVar10 = cb.c10007980
puVar9 = cb.c1000cee0
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(2.1)
W(((fVar1 + 1.0) * 3.141592653), uVar3, uVar4, uVar5,  fVar6, uVar7, uVar8, puVar9, puVar10)
end
effects[11] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c100079e0
puVar4 = cb.c1000cba0
uVar3 = 0
uVar2 = 0
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[12] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c10007ae0
puVar4 = cb.c10007a80
uVar3 = 0
uVar2 = 0
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
end
effects[13] = function(G, W)

local fVar1, fVar6, lVar2, puVar10, puVar9, uVar3, uVar4, uVar5, uVar7, uVar8
puVar10 = cb.c10009070
puVar9 = cb.c10007b80
uVar8 = 0
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(5.0)
W(((fVar1 + 28.0) * 3.141592653), uVar3, uVar4, uVar5,  fVar6, uVar7, uVar8, puVar9, puVar10)
end
effects[14] = function(G, W)

local lVar1, pcVar4, puVar5, uVar2, uVar3
puVar5 = cb.c10007da0
pcVar4 = cb.c10007c60
uVar3 = 1
uVar2 = 1
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, pcVar4, puVar5)
end
effects[15] = function(G, W)

local fVar1, fVar6, lVar2, puVar10, puVar9, uVar3, uVar4, uVar5, uVar7, uVar8
puVar10 = cb.c10007da0
puVar9 = cb.c10007cd0
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(120.0)
W(fVar1, uVar3, uVar4, uVar5, fVar6, uVar7, uVar8, puVar9, puVar10)
end
effects[16] = function(G, W)

local fVar1, fVar3, fVar6, lVar2, pcVar10, puVar9, uVar4, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ad0
puVar9 = cb.c10008aa0
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
fVar1 = R(80.0)
fVar3 = fVar1
fVar1 = R(0.15)
W(fVar1, fVar3, uVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
G.d10028fd0 = 0xc
end
effects[17] = function(G, W)

local fVar1, fVar6, lVar2, pcVar10, pcVar9, uVar3, uVar4, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ba0
pcVar9 = cb.c10008b60
uVar8 = 0
uVar7 = 0
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(0.07)
W(fVar1, uVar3, uVar4, uVar5, fVar6, uVar7, uVar8, pcVar9, pcVar10)
end
effects[18] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ee0
puVar9 = cb.c10008c20
uVar8 = 0
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 0.9)
fVar1 = R(7.0)
fVar3 = (fVar1 + 3.0)
fVar1 = R(0.08)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[19] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ee0
puVar9 = cb.c10008c20
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 0.9)
fVar1 = R(7.0)
fVar3 = (fVar1 + 3.0)
fVar1 = R(0.08)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[20] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ee0
puVar9 = cb.c10008d00
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 1.6)
fVar1 = R(7.0)
fVar3 = (fVar1 + 3.0)
fVar1 = R(0.05)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[21] = function(G, W)

local fVar1, fVar6, lVar2, pcVar9, puVar10, uVar3, uVar4, uVar5, uVar7, uVar8
puVar10 = cb.c10009070
pcVar9 = cb.c100092e0
uVar8 = 0
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(5.0)
W(((fVar1 + 8.0) * 3.141592653), uVar3, uVar4, uVar5,  fVar6, uVar7, uVar8, pcVar9, puVar10)
end
effects[22] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008dd0
puVar9 = cb.c10008d00
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 1.6)
fVar1 = R(1000.0)
fVar3 = (fVar1 + 7.0)
fVar1 = R(0.05)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[23] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ee0
puVar9 = cb.c10008c20
uVar8 = 1
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 0.9)
fVar1 = R(1000.0)
fVar3 = fVar1
fVar1 = R(0.08)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[24] = function(G, W)

local fVar1, fVar3, fVar4, fVar6, lVar2, pcVar10, puVar9, uVar5, uVar7, uVar8
pcVar10 = cb.c10008ee0
puVar9 = cb.c10008c20
uVar8 = 0
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
fVar1 = R(0.3)
fVar4 = (fVar1 + 0.6)
fVar1 = R(1000.0)
fVar3 = fVar1
fVar1 = R(0.08)
W(fVar1, fVar3, fVar4, uVar5, fVar6, uVar7, uVar8, puVar9, pcVar10)
end
effects[25] = function(G, W)

local fVar1, fVar2, fVar3, puVar8, puVar9, uVar4, uVar5, uVar6, uVar7
puVar9 = cb.c10008fb0
puVar8 = cb.c10008f80
uVar7 = 1
uVar6 = 1
uVar5 = 0
uVar4 = 0
fVar1 = R(5.0)
fVar3 = ((fVar1 + 8.0) * 3.141592653)
fVar1 = R(100.0)
fVar2 = fVar1
fVar1 = R(0.02)
W(fVar1, fVar2, fVar3, uVar4, uVar5, uVar6, uVar7, puVar8, puVar9)
end
effects[26] = function(G, W)

local fVar1, fVar3, fVar5, lVar2, puVar13, puVar15, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009870
puVar13 = cb.c10009850
lVar2 = I(1)
uVar6 = lVar2
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = Q()
fVar5 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, fVar5, uVar7, uVar9, uVar12, uVar6,  puVar13, puVar15)
end
effects[27] = function(G, W)

local fVar1, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar8, uVar9
puVar15 = cb.c100098f0
puVar13 = cb.c10009970
uVar8 = 0
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(100.0)
W((fVar1 + 5.0), uVar6, uVar7, uVar9, uVar12, uVar11, uVar8,  puVar13, puVar15)
end
effects[28] = function(G, W)

local fVar1, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar8, uVar9
puVar15 = cb.c100099b0
puVar13 = cb.c10009970
uVar8 = 0
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
uVar6 = 0x40400000
fVar1 = R(50.0)
W((fVar1 + 50.0), uVar6, uVar7, uVar9, uVar12, uVar11, uVar8,  puVar13, puVar15)
end
effects[29] = function(G, W)

local fVar1, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009a30
puVar13 = cb.c10009ac0
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(25.0)
W(0x40e00000, (fVar1 + 25.0), uVar6, uVar7, uVar9, uVar12, uVar11,  puVar13, puVar15)
G.d10028fd0 = 0xd
G.d10028fc8 = 0
end
effects[30] = function(G, W)

local fVar1, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar8, uVar9
puVar15 = cb.c10009b00
puVar13 = cb.c10009ac0
uVar8 = 0
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(100.0)
W((fVar1 + 5.0), uVar6, uVar7, uVar9, uVar12, uVar11, uVar8,  puVar13, puVar15)
end
effects[31] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c1000cb10
puVar13 = cb.c10009bd0
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[32] = function(G, W)

local fVar1, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar8, uVar9
puVar15 = cb.c1000cb10
puVar13 = cb.c10009bd0
lVar2 = I(1)
uVar6 = lVar2
uVar8 = 0
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0x40400000
fVar1 = R(50.0)
W((fVar1 + 50.0), uVar7, uVar9, uVar12, uVar11, uVar8, uVar6,  puVar13, puVar15)
G.d10028fd0 = 0xd
end
effects[33] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c1000cb10
puVar13 = cb.c10009c40
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 50.0)
fVar1 = R(50.0)
W((fVar1 + 50.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[34] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009cb0
puVar13 = cb.c10009bd0
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[35] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009d70
puVar13 = cb.c10009e00
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 50.0)
fVar1 = R(50.0)
W((fVar1 + 50.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[36] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009d70
puVar13 = cb.c10009e00
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(27.0)
fVar5 = (fVar1 + 3.0)
fVar1 = R(27.0)
W((fVar1 + 3.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[37] = function(G, W)

local fVar1, fVar5, lVar2, puVar13, puVar15, uVar11, uVar12, uVar6, uVar7, uVar9
puVar15 = cb.c10009d70
puVar13 = cb.c10009e00
lVar2 = I(1)
uVar6 = lVar2
uVar11 = 0
uVar12 = 0
uVar9 = 0
uVar7 = 0
fVar1 = R(7.0)
fVar5 = (fVar1 + 3.0)
fVar1 = R(7.0)
W((fVar1 + 3.0), fVar5, uVar7, uVar9, uVar12, uVar11, uVar6,  puVar13, puVar15)
end
effects[38] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000da50
puVar9 = cb.c1000da20
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(100.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(100.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[39] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000daf0
puVar9 = cb.c1000dad0
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(100.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(100.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[40] = function(G, W)


W(0, 0, 0, 0, 0, 0, 1, cb.c1000db60, cb.c1000db90)
end
effects[41] = function(G, W)

local lVar2
W(0, 0, 0, 0, 0, 0, 1, cb.c1000dbf0, cb.c1000dc00)
lVar2 = I(1)
G.d10028fd0 = auStackY_250[lVar2 + 0x8a]
end
effects[42] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000dca0
puVar9 = cb.c1000ce40
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(100.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(100.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[43] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000ce60
puVar9 = cb.c1000ce40
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(10.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(10.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[44] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000dd80
puVar9 = cb.c1000dd60
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(10.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(10.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[45] = function(G, W)

local fVar1, fVar3, lVar2, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000ddf0
puVar9 = cb.c1000d220
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(5.0)
fVar3 = (fVar1 + 2.0)
fVar1 = R(5.0)
W((fVar1 + 2.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
lVar2 = I(1)
G.d10028fd0 = auStackY_250[lVar2 + 0x89]
end
effects[46] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000df00
puVar9 = cb.c1000ded0
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[47] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000dfb0
puVar9 = cb.c1000df80
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[48] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000e050
puVar9 = cb.c1000e030
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[49] = function(G, W)

local fVar1, fVar3, lVar2, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000e100
puVar9 = cb.c1000e0d0
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
G.d100ad3ec = 1
G.d10028f98 = 3
lVar2 = I(1)
G.d10028fd0 = auStackY_250[lVar2 + 0x8e]
end
effects[50] = function(G, W)


W(0, 0, 0, 0, 0, 0, 1, cb.c1000e1d0, cb.c1000e200)
end
effects[51] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000e3d0
puVar9 = cb.c1000e350
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(100.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(100.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[52] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000e3d0
puVar9 = cb.c1000e350
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(5.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(5.0)
W((fVar1 + 5.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[53] = function(G, W)

local fVar1, fVar3, puVar10, puVar9, uVar4, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000e3d0
puVar9 = cb.c1000e350
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(100.0)
fVar3 = (fVar1 + 100.0)
fVar1 = R(100.0)
W((fVar1 + 100.0), fVar3, uVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
end
effects[54] = function(G, W)
local local_14 = {}
local fVar1, fVar3, fVar4, lVar2, puVar10, puVar9, uVar5, uVar6, uVar7, uVar8
puVar10 = cb.c1000d3b0
puVar9 = cb.c1000ab40
uVar8 = 1
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.16)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar3, fVar4, uVar5, uVar6, uVar7, uVar8, puVar9,  puVar10)
G.d10028fc8 = 0
local_14[0] = 1
local_14[1] = 3
local_14[2] = 9
local_14[3] = 0xf
local_14[4] = 0x10
lVar2 = I(5)
G.d10028fd0 = local_14[lVar2]
end
effects[55] = function(G, W)

local fVar1, fVar6, lVar2, pcVar10, pcVar9, uVar3, uVar4, uVar5, uVar7, uVar8
pcVar10 = cb.c1000d540
pcVar9 = cb.c1000d4b0
uVar8 = 0
uVar7 = 1
lVar2 = I(2)
fVar6 = lVar2
uVar5 = 0
uVar4 = 0
uVar3 = 0
fVar1 = R(5.0)
W((fVar1 * 3.141592653 + 8.0), uVar3, uVar4, uVar5,  fVar6, uVar7, uVar8, pcVar9, pcVar10)
G.d10028fc8 = 0
end
effects[56] = function(G, W)

local fVar1, fVar2, fVar3, puVar8, puVar9, uVar4, uVar5, uVar6, uVar7
puVar9 = cb.c1000ac50
puVar8 = cb.c1000ac00
uVar7 = 0
uVar6 = 0
uVar5 = 0
uVar4 = 0
fVar1 = R(0.04)
fVar3 = fVar1
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, uVar4, uVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[57] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, puVar8, puVar9, uVar5, uVar6, uVar7
puVar9 = cb.c1000ad20
puVar8 = cb.c1000ace0
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(50.0)
fVar4 = (fVar1 + 50.0)
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[58] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, puVar8, puVar9, uVar5, uVar6, uVar7
puVar9 = cb.c1000ae30
puVar8 = cb.c1000adc0
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.04)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[59] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, pcVar9, puVar8, uVar5, uVar6, uVar7
pcVar9 = cb.c1000afb0
puVar8 = cb.c1000aef0
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.02)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  pcVar9)
end
effects[60] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, pcVar9, puVar8, uVar5, uVar6, uVar7
pcVar9 = cb.c1000b140
puVar8 = cb.c1000b0c0
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.02)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.96), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  pcVar9)
end
effects[61] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, pcVar9, puVar8, uVar5, uVar6, uVar7
pcVar9 = cb.c1000b2d0
puVar8 = cb.c1000b250
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.02)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  pcVar9)
end
effects[62] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, puVar8, puVar9, uVar5, uVar6, uVar7
puVar9 = cb.c1000b470
puVar8 = cb.c1000b3e0
uVar7 = 0
uVar6 = 0
uVar5 = 0
fVar1 = R(0.04)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, uVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[63] = function(G, W)

local fVar1, fVar2, fVar3, fVar4, fVar5, puVar8, puVar9, uVar6, uVar7
puVar9 = cb.c1000b5f0
puVar8 = cb.c1000b550
uVar7 = 0
uVar6 = 0
fVar1 = R(0.03)
fVar5 = fVar1
fVar1 = R(0.06)
fVar4 = fVar1
fVar1 = R(50.0)
fVar3 = (fVar1 + 5.0)
fVar1 = R(50.0)
fVar2 = (fVar1 + 5.0)
fVar1 = R(0.03)
W((fVar1 + 0.97), fVar2, fVar3, fVar4, fVar5, uVar6, uVar7, puVar8,  puVar9)
end
effects[64] = function(G, W)

local fVar1, puVar10, puVar9, uVar11, uVar12, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000c920
puVar9 = cb.c1000c900
uVar12 = 0
uVar13 = 0
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(50.0)
W((fVar1 + 5.0), uVar6, uVar7, uVar8, uVar11, uVar13, uVar12,  puVar9, puVar10)
G.d10028fd0 = 0xc
end
effects[65] = function(G, W)

local lVar1, puVar4, puVar5, uVar2, uVar3
puVar5 = cb.c1000c9e0
puVar4 = cb.c1000c980
uVar3 = 1
uVar2 = 1
lVar1 = I(2)
W(0, 0, 0, 0, lVar1, uVar2, uVar3, puVar4, puVar5)
G.d10028fd0 = 9
end
effects[66] = function(G, W)

local fVar1, fVar5, lVar2, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c10009070
puVar9 = cb.c10007b80
uVar13 = 0
uVar11 = 1
lVar2 = I(1)
fVar5 = lVar2
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(5.0)
W((fVar1 * 3.141592653 + 8.0), uVar6, uVar7, uVar8,  fVar5, uVar11, uVar13, puVar9, puVar10)
G.d10028fd0 = 0xd
end
effects[67] = function(G, W)

local fVar1, fVar4, fVar5, puVar10, puVar9, uVar11, uVar6, uVar7, uVar8
puVar10 = cb.c1000ca80
puVar9 = cb.c1000ca50
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(0.16)
fVar5 = fVar1
fVar1 = R(50.0)
fVar4 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar4, fVar5, uVar6, uVar7, uVar8, uVar11, puVar9 , puVar10)
G.d10028fd0 = 0xb
end
effects[68] = function(G, W)

local fVar1, fVar5, lVar2, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000cb10
puVar9 = cb.c10009bd0
uVar13 = 0
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar5, uVar6, uVar7, uVar8, uVar11, uVar13,  puVar9, puVar10)
lVar2 = I(1)
G.d10028fd0 = auStackY_238[lVar2 + 0x8b]
end
effects[69] = function(G, W)

local fVar1, fVar5, lVar2, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000cc00
puVar9 = cb.c1000cba0
uVar13 = 0
uVar11 = 0
lVar2 = I(1)
fVar5 = lVar2
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(0.13)
W(fVar1, uVar6, uVar7, uVar8, fVar5, uVar11, uVar13, puVar9, puVar10)
G.d10028fd0 = 0x10
end
effects[70] = function(G, W)

local fVar1, fVar5, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000a4d0
puVar9 = cb.c1000a4a0
uVar13 = 1
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar5, uVar6, uVar7, uVar8, uVar11, uVar13,  puVar9, puVar10)
G.d10028fd0 = 0xb
G.d10028fc8 = 0
end
effects[71] = function(G, W)

local fVar1, fVar5, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000cd40
puVar9 = cb.c1000cd10
uVar13 = 0
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(50.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(50.0)
W((fVar1 + 5.0), fVar5, uVar6, uVar7, uVar8, uVar11, uVar13,  puVar9, puVar10)
G.d10028fd0 = 8
end
effects[72] = function(G, W)

local fVar1, fVar5, lVar2, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c10007da0
puVar9 = cb.c1000cdc0
uVar13 = 1
uVar11 = 1
lVar2 = I(1)
fVar5 = lVar2
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(80.0)
W(fVar1, uVar6, uVar7, uVar8, fVar5, uVar11, uVar13, puVar9, puVar10)
G.d10028fd0 = 2
end
effects[73] = function(G, W)

local fVar1, fVar5, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c1000ce60
puVar9 = cb.c1000ce40
uVar13 = 1
uVar11 = 0
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(10.0)
fVar5 = (fVar1 + 5.0)
fVar1 = R(10.0)
W((fVar1 + 5.0), fVar5, uVar6, uVar7, uVar8, uVar11, uVar13,  puVar9, puVar10)
G.d10028fd0 = 0xd
G.d10028fc8 = 0
end
effects[74] = function(G, W)

local fVar1, fVar5, lVar2, puVar10, puVar9, uVar11, uVar13, uVar6, uVar7, uVar8
puVar10 = cb.c10007980
puVar9 = cb.c1000cee0
uVar13 = 1
uVar11 = 1
lVar2 = I(1)
fVar5 = lVar2
uVar8 = 0
uVar7 = 0
uVar6 = 0
fVar1 = R(2.1)
W(((fVar1 + 1.0) * 3.141592653), uVar6, uVar7,  uVar8, fVar5, uVar11, uVar13, puVar9, puVar10)
G.d10028fd0 = 0xb
end
return { effects = effects, cats = { { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 14, 15, 15 }, { 16, 16, 16, 17, 17, 18, 19, 20, 21, 22, 23, 24, 25 }, { 26, 26, 26, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37 }, { 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53 }, { 54, 55, 56, 57, 58, 59, 60, 61, 62, 63 }, { 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74 } } }
end
