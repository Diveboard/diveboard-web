module DecoHelper

  # [depth, duration, 15m, 12m, 9m, 6m, 3m, DTR, GPS, total dive duration (incl. 3mn safety stop)]
  MN90 = [[6, 15, nil, nil, nil, nil, nil, 1, "A", 19],
    [6, 30, nil, nil, nil, nil, nil, 1, "B", 34],
    [6, 45, nil, nil, nil, nil, nil, 1, "C", 49],
    [6, 75, nil, nil, nil, nil, nil, 1, "D", 79],
    [6, 105, nil, nil, nil, nil, nil, 1, "E", 109],
    [6, 135, nil, nil, nil, nil, nil, 1, "F", 139],
    [6, 180, nil, nil, nil, nil, nil, 1, "G", 184],
    [6, 240, nil, nil, nil, nil, nil, 1, "H", 244],
    [6, 315, nil, nil, nil, nil, nil, 1, "I", 319],
    [6, 360, nil, nil, nil, nil, nil, 1, "J", 364],
    [8, 15, nil, nil, nil, nil, nil, 1, "B", 19],
    [8, 30, nil, nil, nil, nil, nil, 1, "C", 34],
    [8, 45, nil, nil, nil, nil, nil, 1, "D", 49],
    [8, 60, nil, nil, nil, nil, nil, 1, "E", 64],
    [8, 90, nil, nil, nil, nil, nil, 1, "F", 94],
    [8, 105, nil, nil, nil, nil, nil, 1, "G", 109],
    [8, 135, nil, nil, nil, nil, nil, 1, "H", 139],
    [8, 165, nil, nil, nil, nil, nil, 1, "I", 169],
    [8, 195, nil, nil, nil, nil, nil, 1, "J", 199],
    [8, 255, nil, nil, nil, nil, nil, 1, "K", 259],
    [8, 300, nil, nil, nil, nil, nil, 1, "L", 304],
    [8, 360, nil, nil, nil, nil, nil, 1, "M", 364],
    [10, 15, nil, nil, nil, nil, nil, 1, "B", 19],
    [10, 30, nil, nil, nil, nil, nil, 1, "C", 34],
    [10, 45, nil, nil, nil, nil, nil, 1, "D", 49],
    [10, 60, nil, nil, nil, nil, nil, 1, "F", 64],
    [10, 75, nil, nil, nil, nil, nil, 1, "G", 79],
    [10, 105, nil, nil, nil, nil, nil, 1, "H", 109],
    [10, 120, nil, nil, nil, nil, nil, 1, "I", 124],
    [10, 135, nil, nil, nil, nil, nil, 1, "J", 139],
    [10, 165, nil, nil, nil, nil, nil, 1, "K", 169],
    [10, 180, nil, nil, nil, nil, nil, 1, "L", 184],
    [10, 240, nil, nil, nil, nil, nil, 1, "M", 244],
    [10, 255, nil, nil, nil, nil, nil, 1, "N", 259],
    [10, 315, nil, nil, nil, nil, nil, 1, "O", 319],
    [10, 330, nil, nil, nil, nil, nil, 1, "P", 334],
    [10, 360, nil, nil, nil, nil, 1, 2, "P", 366],
    [12, 5, nil, nil, nil, nil, nil, 1, "A", 9],
    [12, 10, nil, nil, nil, nil, nil, 1, "B", 14],
    [12, 15, nil, nil, nil, nil, nil, 1, "B", 19],
    [12, 20, nil, nil, nil, nil, nil, 1, "C", 24],
    [12, 25, nil, nil, nil, nil, nil, 1, "C", 29],
    [12, 30, nil, nil, nil, nil, nil, 1, "D", 34],
    [12, 35, nil, nil, nil, nil, nil, 1, "D", 39],
    [12, 40, nil, nil, nil, nil, nil, 1, "E", 44],
    [12, 45, nil, nil, nil, nil, nil, 1, "E", 49],
    [12, 50, nil, nil, nil, nil, nil, 1, "F", 54],
    [12, 55, nil, nil, nil, nil, nil, 1, "F", 59],
    [12, 60, nil, nil, nil, nil, nil, 1, "G", 64],
    [12, 65, nil, nil, nil, nil, nil, 1, "G", 69],
    [12, 70, nil, nil, nil, nil, nil, 1, "H", 74],
    [12, 75, nil, nil, nil, nil, nil, 1, "H", 79],
    [12, 80, nil, nil, nil, nil, nil, 1, "H", 84],
    [12, 85, nil, nil, nil, nil, nil, 1, "I", 89],
    [12, 90, nil, nil, nil, nil, nil, 1, "I", 94],
    [12, 95, nil, nil, nil, nil, nil, 1, "J", 99],
    [12, 100, nil, nil, nil, nil, nil, 1, "J", 104],
    [12, 105, nil, nil, nil, nil, nil, 1, "J", 109],
    [12, 110, nil, nil, nil, nil, nil, 1, "K", 114],
    [12, 115, nil, nil, nil, nil, nil, 1, "K", 119],
    [12, 120, nil, nil, nil, nil, nil, 1, "K", 124],
    [12, 130, nil, nil, nil, nil, nil, 1, "L", 134],
    [12, 135, nil, nil, nil, nil, nil, 1, "L", 139],
    [12, 140, nil, nil, nil, nil, 2, 4, "L", 149],
    [12, 150, nil, nil, nil, nil, 4, 6, "M", 163],
    [12, 160, nil, nil, nil, nil, 6, 8, "M", 177],
    [12, 170, nil, nil, nil, nil, 7, 9, "N", 189],
    [12, 180, nil, nil, nil, nil, 9, 11, "N", 203],
    [12, 190, nil, nil, nil, nil, 11, 13, "N", 217],
    [12, 200, nil, nil, nil, nil, 13, 15, "O", 231],
    [12, 210, nil, nil, nil, nil, 14, 16, "O", 243],
    [12, 220, nil, nil, nil, nil, 15, 17, "O", 255],
    [12, 230, nil, nil, nil, nil, 16, 18, "O", 267],
    [12, 240, nil, nil, nil, nil, 17, 19, "O", 279],
    [12, 250, nil, nil, nil, nil, 18, 20, "P", 291],
    [12, 255, nil, nil, nil, nil, 19, 21, "P", 298],
    [12, 270, nil, nil, nil, nil, 22, 24, "P", 319],
    [15, 5, nil, nil, nil, nil, nil, 1, "A", 9],
    [15, 10, nil, nil, nil, nil, nil, 1, "B", 14],
    [15, 15, nil, nil, nil, nil, nil, 1, "C", 19],
    [15, 20, nil, nil, nil, nil, nil, 1, "C", 24],
    [15, 25, nil, nil, nil, nil, nil, 1, "D", 29],
    [15, 30, nil, nil, nil, nil, nil, 1, "E", 34],
    [15, 35, nil, nil, nil, nil, nil, 1, "E", 39],
    [15, 40, nil, nil, nil, nil, nil, 1, "F", 44],
    [15, 45, nil, nil, nil, nil, nil, 1, "G", 49],
    [15, 50, nil, nil, nil, nil, nil, 1, "G", 54],
    [15, 55, nil, nil, nil, nil, nil, 1, "H", 59],
    [15, 60, nil, nil, nil, nil, nil, 1, "H", 64],
    [15, 65, nil, nil, nil, nil, nil, 1, "I", 69],
    [15, 70, nil, nil, nil, nil, nil, 1, "I", 74],
    [15, 75, nil, nil, nil, nil, nil, 1, "J", 79],
    [15, 80, nil, nil, nil, nil, 2, 4, "J", 89],
    [15, 85, nil, nil, nil, nil, 4, 6, "K", 98],
    [15, 90, nil, nil, nil, nil, 6, 8, "K", 107],
    [15, 95, nil, nil, nil, nil, 8, 10, "L", 116],
    [15, 100, nil, nil, nil, nil, 11, 13, "L", 127],
    [15, 105, nil, nil, nil, nil, 13, 15, "L", 136],
    [15, 110, nil, nil, nil, nil, 15, 17, "M", 145],
    [15, 115, nil, nil, nil, nil, 17, 19, "M", 154],
    [15, 120, nil, nil, nil, nil, 18, 20, "M", 161],
    [18, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [18, 10, nil, nil, nil, nil, nil, 2, "B", 15],
    [18, 15, nil, nil, nil, nil, nil, 2, "C", 20],
    [18, 20, nil, nil, nil, nil, nil, 2, "D", 25],
    [18, 25, nil, nil, nil, nil, nil, 2, "E", 30],
    [18, 30, nil, nil, nil, nil, nil, 2, "F", 35],
    [18, 35, nil, nil, nil, nil, nil, 2, "F", 40],
    [18, 40, nil, nil, nil, nil, nil, 2, "G", 45],
    [18, 45, nil, nil, nil, nil, nil, 2, "H", 50],
    [18, 50, nil, nil, nil, nil, nil, 2, "H", 55],
    [18, 55, nil, nil, nil, nil, 1, 3, "I", 62],
    [18, 60, nil, nil, nil, nil, 5, 7, "J", 75],
    [18, 65, nil, nil, nil, nil, 8, 10, "J", 86],
    [18, 70, nil, nil, nil, nil, 11, 13, "K", 97],
    [18, 75, nil, nil, nil, nil, 14, 16, "K", 108],
    [18, 80, nil, nil, nil, nil, 17, 19, "L", 119],
    [18, 85, nil, nil, nil, nil, 21, 23, "L", 132],
    [18, 90, nil, nil, nil, nil, 23, 25, "M", 141],
    [18, 95, nil, nil, nil, nil, 26, 28, "M", 152],
    [18, 100, nil, nil, nil, nil, 28, 30, "M", 161],
    [18, 105, nil, nil, nil, nil, 31, 33, "N", 172],
    [18, 110, nil, nil, nil, nil, 34, 36, "N", 183],
    [18, 115, nil, nil, nil, nil, 36, 38, "N", 192],
    [18, 120, nil, nil, nil, nil, 38, 40, "O", 201],
    [20, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [20, 10, nil, nil, nil, nil, nil, 2, "B", 15],
    [20, 15, nil, nil, nil, nil, nil, 2, "D", 20],
    [20, 20, nil, nil, nil, nil, nil, 2, "D", 25],
    [20, 25, nil, nil, nil, nil, nil, 2, "E", 30],
    [20, 30, nil, nil, nil, nil, nil, 2, "F", 35],
    [20, 35, nil, nil, nil, nil, nil, 2, "G", 40],
    [20, 40, nil, nil, nil, nil, nil, 2, "H", 45],
    [20, 45, nil, nil, nil, nil, 1, 3, "I", 52],
    [20, 50, nil, nil, nil, nil, 4, 6, "I", 63],
    [20, 55, nil, nil, nil, nil, 9, 11, "J", 78],
    [20, 60, nil, nil, nil, nil, 13, 15, "K", 91],
    [20, 65, nil, nil, nil, nil, 16, 18, "K", 102],
    [20, 70, nil, nil, nil, nil, 20, 22, "L", 115],
    [20, 75, nil, nil, nil, nil, 24, 26, "L", 128],
    [20, 80, nil, nil, nil, nil, 27, 29, "M", 139],
    [20, 85, nil, nil, nil, nil, 30, 32, "M", 150],
    [20, 90, nil, nil, nil, nil, 34, 36, "M", 163],
    [22, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [22, 10, nil, nil, nil, nil, nil, 2, "C", 15],
    [22, 15, nil, nil, nil, nil, nil, 2, "D", 20],
    [22, 20, nil, nil, nil, nil, nil, 2, "E", 25],
    [22, 25, nil, nil, nil, nil, nil, 2, "F", 30],
    [22, 30, nil, nil, nil, nil, nil, 2, "G", 35],
    [22, 35, nil, nil, nil, nil, nil, 2, "H", 40],
    [22, 40, nil, nil, nil, nil, 2, 4, "I", 49],
    [22, 45, nil, nil, nil, nil, 7, 9, "I", 64],
    [22, 50, nil, nil, nil, nil, 12, 14, "J", 79],
    [22, 55, nil, nil, nil, nil, 16, 18, "K", 92],
    [22, 60, nil, nil, nil, nil, 20, 22, "K", 105],
    [22, 65, nil, nil, nil, nil, 25, 27, "L", 120],
    [22, 70, nil, nil, nil, nil, 29, 31, "L", 133],
    [22, 75, nil, nil, nil, nil, 33, 35, "M", 146],
    [22, 80, nil, nil, nil, nil, 37, 39, "M", 159],
    [22, 85, nil, nil, nil, nil, 41, 43, "N", 172],
    [22, 90, nil, nil, nil, nil, 44, 46, "N", 183],
    [25, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [25, 10, nil, nil, nil, nil, nil, 2, "C", 15],
    [25, 15, nil, nil, nil, nil, nil, 2, "D", 20],
    [25, 20, nil, nil, nil, nil, nil, 2, "E", 25],
    [25, 25, nil, nil, nil, nil, 1, 3, "F", 32],
    [25, 30, nil, nil, nil, nil, 2, 4, "H", 39],
    [25, 35, nil, nil, nil, nil, 5, 7, "I", 50],
    [25, 40, nil, nil, nil, nil, 10, 12, "J", 65],
    [25, 45, nil, nil, nil, nil, 16, 18, "J", 82],
    [25, 50, nil, nil, nil, nil, 21, 23, "K", 97],
    [25, 55, nil, nil, nil, nil, 27, 29, "L", 114],
    [25, 60, nil, nil, nil, nil, 32, 34, "L", 129],
    [25, 65, nil, nil, nil, nil, 37, 39, "M", 144],
    [25, 70, nil, nil, nil, 1, 41, 45, "M", 160],
    [25, 75, nil, nil, nil, 4, 43, 50, "N", 175],
    [25, 80, nil, nil, nil, 7, 45, 55, "N", 190],
    [25, 85, nil, nil, nil, 9, 48, 60, "O", 205],
    [25, 90, nil, nil, nil, 11, 50, 64, "O", 218],
    [28, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [28, 10, nil, nil, nil, nil, nil, 2, "D", 15],
    [28, 15, nil, nil, nil, nil, nil, 2, "E", 20],
    [28, 20, nil, nil, nil, nil, 1, 4, "F", 28],
    [28, 25, nil, nil, nil, nil, 2, 5, "G", 35],
    [28, 30, nil, nil, nil, nil, 6, 9, "H", 48],
    [28, 35, nil, nil, nil, nil, 12, 15, "I", 65],
    [28, 40, nil, nil, nil, nil, 19, 22, "J", 84],
    [28, 45, nil, nil, nil, nil, 25, 28, "K", 101],
    [28, 50, nil, nil, nil, nil, 32, 35, "L", 120],
    [28, 55, nil, nil, nil, 2, 36, 41, "M", 137],
    [28, 60, nil, nil, nil, 4, 40, 47, "M", 154],
    [28, 65, nil, nil, nil, 8, 43, 54, "N", 173],
    [28, 70, nil, nil, nil, 11, 46, 60, "N", 190],
    [28, 75, nil, nil, nil, 14, 48, 65, "O", 205],
    [28, 80, nil, nil, nil, 17, 50, 70, "O", 220],
    [28, 85, nil, nil, nil, 20, 53, 76, "O", 237],
    [28, 90, nil, nil, nil, 23, 56, 82, "P", 254],
    [30, 5, nil, nil, nil, nil, nil, 2, "B", 10],
    [30, 10, nil, nil, nil, nil, nil, 2, "D", 15],
    [30, 15, nil, nil, nil, nil, 1, 4, "E", 23],
    [30, 20, nil, nil, nil, nil, 2, 5, "F", 30],
    [30, 25, nil, nil, nil, nil, 4, 7, "H", 39],
    [30, 30, nil, nil, nil, nil, 9, 12, "I", 54],
    [30, 35, nil, nil, nil, nil, 17, 20, "J", 75],
    [30, 40, nil, nil, nil, nil, 24, 27, "K", 94],
    [30, 45, nil, nil, nil, 1, 31, 35, "L", 115],
    [30, 50, nil, nil, nil, 3, 36, 42, "M", 134],
    [30, 55, nil, nil, nil, 6, 39, 48, "M", 151],
    [30, 60, nil, nil, nil, 10, 43, 56, "N", 172],
    [30, 65, nil, nil, nil, 14, 46, 63, "N", 191],
    [30, 70, nil, nil, nil, 17, 48, 68, "O", 206],
    [32, 5, nil, nil, nil, nil, nil, 3, "B", 11],
    [32, 10, nil, nil, nil, nil, nil, 3, "D", 16],
    [32, 15, nil, nil, nil, nil, 1, 4, "E", 23],
    [32, 20, nil, nil, nil, nil, 3, 6, "G", 32],
    [32, 25, nil, nil, nil, nil, 6, 9, "H", 43],
    [32, 30, nil, nil, nil, nil, 14, 17, "I", 64],
    [32, 35, nil, nil, nil, nil, 22, 25, "K", 85],
    [32, 40, nil, nil, nil, 1, 29, 33, "K", 106],
    [32, 45, nil, nil, nil, 4, 34, 41, "L", 127],
    [32, 50, nil, nil, nil, 7, 39, 49, "M", 148],
    [32, 55, nil, nil, nil, 11, 43, 57, "N", 169],
    [32, 60, nil, nil, nil, 15, 46, 64, "N", 188],
    [32, 65, nil, nil, nil, 19, 48, 70, "O", 205],
    [32, 70, nil, nil, nil, 23, 50, 76, "O", 222],
    [35, 5, nil, nil, nil, nil, nil, 3, "C", 11],
    [35, 10, nil, nil, nil, nil, nil, 3, "D", 16],
    [35, 15, nil, nil, nil, nil, 2, 5, "F", 25],
    [35, 20, nil, nil, nil, nil, 5, 8, "H", 36],
    [35, 25, nil, nil, nil, nil, 11, 14, "I", 53],
    [35, 30, nil, nil, nil, 1, 20, 24, "J", 78],
    [35, 35, nil, nil, nil, 2, 27, 32, "K", 99],
    [35, 40, nil, nil, nil, 5, 34, 42, "L", 124],
    [35, 45, nil, nil, nil, 9, 39, 51, "M", 147],
    [35, 50, nil, nil, nil, 14, 43, 60, "N", 170],
    [35, 55, nil, nil, nil, 18, 47, 68, "N", 191],
    [35, 60, nil, nil, nil, 22, 50, 75, "O", 210],
    [35, 65, nil, nil, 2, 26, 52, 84, nil, 232],
    [35, 70, nil, nil, 4, 28, 57, 93, nil, 255],
    [38, 5, nil, nil, nil, nil, nil, 3, "C", 11],
    [38, 10, nil, nil, nil, nil, 1, 4, "E", 18],
    [38, 15, nil, nil, nil, nil, 4, 7, "F", 29],
    [38, 20, nil, nil, nil, nil, 8, 11, "H", 42],
    [38, 25, nil, nil, nil, 1, 16, 21, "J", 66],
    [38, 30, nil, nil, nil, 3, 24, 31, "K", 91],
    [38, 35, nil, nil, nil, 5, 33, 42, "L", 118],
    [38, 40, nil, nil, nil, 10, 38, 52, "M", 143],
    [38, 45, nil, nil, nil, 15, 43, 62, "N", 168],
    [38, 50, nil, nil, nil, 20, 47, 71, "N", 191],
    [38, 55, nil, nil, 2, 23, 50, 79, "O", 212],
    [38, 60, nil, nil, 5, 27, 53, 89, "P", 237],
    [38, 65, nil, nil, 8, 29, 58, 99, nil, 262],
    [38, 70, nil, nil, 11, 31, 62, 108, nil, 285],
    [40, 5, nil, nil, nil, nil, nil, 3, "C", 11],
    [40, 10, nil, nil, nil, nil, 2, 5, "E", 20],
    [40, 15, nil, nil, nil, nil, 4, 7, "G", 29],
    [40, 20, nil, nil, nil, 1, 9, 14, "H", 47],
    [40, 25, nil, nil, nil, 2, 19, 25, "J", 74],
    [40, 30, nil, nil, nil, 4, 28, 36, "K", 101],
    [40, 35, nil, nil, nil, 8, 35, 47, "L", 128],
    [40, 40, nil, nil, nil, 13, 40, 57, "M", 153],
    [40, 45, nil, nil, 1, 18, 45, 68, "N", 180],
    [40, 50, nil, nil, 2, 23, 48, 77, "O", 203],
    [40, 55, nil, nil, 5, 26, 52, 87, "O", 228],
    [40, 60, nil, nil, 8, 29, 57, 98, "P", 255],
    [40, 65, nil, nil, 12, 31, 61, 108, nil, 280],
    [40, 70, nil, nil, 15, 33, 66, 118, nil, 305],
    [42, 5, nil, nil, nil, nil, nil, 3, "C", 11],
    [42, 10, nil, nil, nil, nil, 2, 6, "E", 21],
    [42, 15, nil, nil, nil, nil, 5, 9, "G", 32],
    [42, 20, nil, nil, nil, 1, 12, 17, "I", 53],
    [42, 25, nil, nil, nil, 3, 22, 29, "J", 82],
    [42, 30, nil, nil, nil, 6, 31, 41, "L", 111],
    [42, 35, nil, nil, nil, 11, 37, 52, "M", 138],
    [42, 40, nil, nil, 1, 16, 43, 64, "N", 167],
    [42, 45, nil, nil, 3, 21, 47, 75, nil, 194],
    [42, 50, nil, nil, 6, 24, 50, 84, nil, 217],
    [42, 55, nil, nil, 8, 29, 55, 96, nil, 246],
    [42, 60, nil, nil, 13, 30, 60, 107, nil, 273],
    [45, 5, nil, nil, nil, nil, nil, 3, "C", 11],
    [45, 10, nil, nil, nil, nil, 3, 7, "F", 23],
    [45, 15, nil, nil, nil, 1, 6, 11, "H", 36],
    [45, 20, nil, nil, nil, 3, 15, 22, "I", 63],
    [45, 25, nil, nil, nil, 5, 25, 34, "K", 92],
    [45, 30, nil, nil, nil, 9, 35, 48, "L", 125],
    [45, 35, nil, nil, 1, 15, 40, 60, "M", 154],
    [45, 40, nil, nil, 3, 20, 46, 73, "N", 185],
    [45, 45, nil, nil, 6, 24, 50, 84, nil, 212],
    [45, 50, nil, nil, 10, 28, 54, 96, nil, 241],
    [45, 55, nil, nil, 14, 30, 60, 108, nil, 270],
    [45, 60, nil, 1, 18, 32, 65, 121, nil, 300],
    [48, 5, nil, nil, nil, nil, nil, 4, "D", 12],
    [48, 10, nil, nil, nil, nil, 4, 8, "F", 25],
    [48, 15, nil, nil, nil, 2, 7, 13, "H", 40],
    [48, 20, nil, nil, nil, 4, 19, 27, "J", 73],
    [48, 25, nil, nil, nil, 7, 30, 41, "K", 106],
    [48, 30, nil, nil, 1, 12, 37, 55, "M", 138],
    [48, 35, nil, nil, 3, 18, 44, 70, "N", 173],
    [48, 40, nil, nil, 6, 23, 48, 82, "O", 202],
    [48, 45, nil, nil, 10, 27, 53, 95, nil, 233],
    [48, 50, nil, 1, 14, 30, 59, 109, nil, 266],
    [48, 55, nil, 2, 18, 32, 64, 121, nil, 295],
    [48, 60, nil, 5, 19, 36, 70, 135, nil, 328],
    [50, 5, nil, nil, nil, nil, 1, 5, "D", 14],
    [50, 10, nil, nil, nil, nil, 4, 8, "F", 25],
    [50, 15, nil, nil, nil, 2, 9, 15, "H", 44],
    [50, 20, nil, nil, nil, 4, 22, 30, "J", 79],
    [50, 25, nil, nil, 1, 8, 32, 46, "L", 115],
    [50, 30, nil, nil, 2, 14, 39, 60, "M", 148],
    [50, 35, nil, nil, 5, 20, 45, 75, "N", 183],
    [50, 40, nil, nil, 9, 24, 50, 88, "O", 214],
    [50, 45, nil, 1, 12, 29, 55, 102, nil, 247],
    [50, 50, nil, 2, 17, 30, 62, 116, nil, 280],
    [50, 55, nil, 5, 19, 34, 67, 130, nil, 313],
    [52, 5, nil, nil, nil, nil, 1, 5, "D", 14],
    [52, 10, nil, nil, nil, 1, 4, 10, "F", 28],
    [52, 15, nil, nil, nil, 3, 10, 18, "I", 49],
    [52, 20, nil, nil, 1, 5, 23, 34, "K", 86],
    [52, 25, nil, nil, 2, 9, 34, 50, "L", 123],
    [52, 30, nil, nil, 4, 15, 41, 65, "M", 158],
    [52, 35, nil, nil, 6, 22, 47, 80, "O", 193],
    [52, 40, nil, 1, 10, 26, 52, 94, "O", 226],
    [52, 45, nil, 2, 15, 29, 59, 110, nil, 263],
    [52, 50, nil, 5, 17, 32, 64, 123, nil, 294],
    [52, 55, nil, 8, 19, 36, 71, 139, nil, 331],
    [55, 5, nil, nil, nil, nil, 1, 5, "D", 14],
    [55, 10, nil, nil, nil, 1, 5, 11, "G", 30],
    [55, 15, nil, nil, nil, 4, 13, 22, "I", 57],
    [55, 20, nil, nil, 1, 6, 27, 39, "K", 96],
    [55, 25, nil, nil, 3, 11, 37, 56, "M", 135],
    [55, 30, nil, nil, 6, 18, 44, 73, "N", 174],
    [55, 35, nil, 1, 9, 23, 50, 88, "O", 209],
    [55, 40, nil, 3, 12, 29, 55, 104, "P", 246],
    [55, 45, nil, 5, 17, 31, 62, 120, nil, 283],
    [55, 50, nil, 8, 19, 35, 69, 136, nil, 320],
    [55, 55, nil, 12, 22, 37, 76, 152, nil, 357],
    [58, 5, nil, nil, nil, nil, 2, 7, "D", 17],
    [58, 10, nil, nil, nil, 2, 5, 12, "G", 32],
    [58, 15, nil, nil, 1, 4, 16, 26, "J", 65],
    [58, 20, nil, nil, 2, 7, 30, 44, "K", 106],
    [58, 25, nil, nil, 4, 13, 40, 62, "M", 147],
    [58, 30, nil, 1, 7, 21, 46, 81, "N", 189],
    [58, 35, nil, 2, 11, 26, 52, 97, "O", 226],
    [58, 40, nil, 5, 15, 30, 59, 115, "P", 267],
    [58, 45, nil, 8, 18, 33, 66, 131, nil, 304],
    [58, 50, 1, 11, 21, 37, 74, 150, nil, 347],
    [58, 55, 3, 14, 23, 39, 83, 168, nil, 388],
    [60, 5, nil, nil, nil, nil, 2, 7, "D", 17],
    [60, 10, nil, nil, nil, 2, 6, 13, "G", 34],
    [60, 15, nil, nil, 1, 4, 19, 29, "J", 71],
    [60, 20, nil, nil, 3, 8, 32, 48, "L", 114],
    [60, 25, nil, nil, 5, 15, 41, 66, "M", 155],
    [60, 30, nil, 1, 8, 22, 48, 85, "O", 197],
    [60, 35, nil, 4, 11, 28, 54, 103, "P", 238],
    [60, 40, nil, 6, 17, 30, 62, 121, "P", 279],
    [60, 45, 1, 9, 19, 35, 69, 139, nil, 320],
    [60, 50, 2, 13, 22, 37, 78, 158, nil, 363],
    [60, 55, 5, 15, 24, 40, 88, 178, nil, 408],
    [62, 5, nil, nil, nil, nil, 2, 7, nil, 17],
    [62, 10, nil, nil, nil, 2, 7, 14, nil, 36],
    [62, 15, nil, nil, 1, 5, 21, 33, nil, 78],
    [65, 5, nil, nil, nil, nil, 3, 8, nil, 19],
    [65, 10, nil, nil, nil, 3, 8, 16, nil, 40],
    [65, 15, nil, nil, 2, 5, 24, 37, nil, 86]]


  MN90_ASCENT_SPEED = 15 # meters per minute

  MN90_N2_RESIDUEL_SURFACE = [15,30,45,60,90,120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480, 510, 540, 570, 600, 630, 660, 690, 720]
  MN90_N2_RESIDUEL = {
    "A" => [0.84, 0.83, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
    "B" => [0.88, 0.88, 0.87, 0.86, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil, nil, nil, nil, nil, nil, nil, nil],
    "C" => [0.92, 0.91, 0.90, 0.89, 0.88, 0.87, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil, nil, nil, nil, nil, nil],
    "D" => [0.97, 0.95, 0.94, 0.93, 0.91, 0.89, 0.88, 0.86, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil, nil, nil, nil],
    "E" => [1.00, 0.98, 0.97, 0.96, 0.93, 0.91, 0.89, 0.88, 0.87, 0.86, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil, nil, nil],
    "F" => [1.05, 1.03, 1.01, 0.99, 0.96, 0.94, 0.91, 0.90, 0.88, 0.87, 0.86, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil],
    "G" => [1.08, 1.06, 1.04, 1.02, 0.98, 0.96, 0.93, 0.91, 0.89, 0.88, 0.87, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81, nil],
    "H" => [1.13, 1.10, 1.08, 1.05, 1.01, 0.98, 0.95, 0.93, 0.91, 0.89, 0.88, 0.86, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81],
    "I" => [1.17, 1.14, 1.11, 1.08, 1.04, 1.00, 0.97, 0.94, 0.92, 0.90, 0.88, 0.87, 0.86, 0.85, 0.84, 0.84, 0.83, 0.83, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81, 0.81],
    "J" => [1.20, 1.17, 1.14, 1.11, 1.06, 1.02, 0.98, 0.96, 0.93, 0.91, 0.89, 0.88, 0.87, 0.86, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81, 0.81],
    "K" => [1.25, 1.21, 1.18, 1.15, 1.09, 1.04, 1.01, 0.97, 0.95, 0.92, 0.90, 0.89, 0.87, 0.86, 0.85, 0.84, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81],
    "L" => [1.29, 1.25, 1.21, 1.17, 1.12, 1.07, 1.02, 0.99, 0.96, 0.93, 0.91, 0.89, 0.88, 0.87, 0.86, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81, 0.81],
    "M" => [1.33, 1.29, 1.25, 1.21, 1.14, 1.09, 1.04, 1.01, 0.97, 0.94, 0.92, 0.90, 0.89, 0.87, 0.86, 0.85, 0.84, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81],
    "N" => [1.37, 1.32, 1.28, 1.24, 1.17, 1.11, 1.06, 1.02, 0.98, 0.95, 0.93, 0.91, 0.89, 0.88, 0.87, 0.85, 0.85, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81],
    "O" => [1.41, 1.36, 1.32, 1.27, 1.20, 1.13, 1.08, 1.04, 1.00, 0.97, 0.94, 0.92, 0.90, 0.88, 0.87, 0.86, 0.85, 0.84, 0.84, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81, 0.81],
    "P" => [1.45, 1.40, 1.35, 1.30, 1.22, 1.15, 1.10, 1.05, 1.01, 0.98, 0.95, 0.93, 0.91, 0.89, 0.87, 0.86, 0.85, 0.84, 0.84, 0.83, 0.83, 0.82, 0.82, 0.82, 0.81, 0.81]}

  MN90_SUCC_MAJOR_DEPTH = [12,15,18,20,22,25,28,30,32,35,38,40,42,45,48,50,52,55,58,60]
  MN90_SUCC_MAJOR_N2 = [0.82,0.84,0.86,0.89,0.92,0.95,0.99,1.03,1.07,1.11,1.16,1.20,1.24,1.29,1.33,1.38,1.42,1.45]
  MN90_SUCC_MAJOR = [[4, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [7, 6, 5, 4, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1],
    [11, 9, 7, 7, 6, 5, 5, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2],
    [17, 13, 11, 10, 9, 8, 7, 7, 6, 6, 5, 5, 5, 4, 4, 4, 4, 4, 3, 3],
    [23, 18, 15, 13, 12, 11, 10, 9, 8, 8, 7, 7, 6, 6, 5, 5, 5, 5, 5, 4],
    [29, 23, 19, 17, 15, 13, 12, 11, 10, 10, 9, 8, 8, 7, 7, 7, 6, 6, 6, 5],
    [38, 30, 24, 22, 20, 17, 15, 14, 13, 12, 11, 11, 10, 9, 9, 8, 8, 8, 7, 7],
    [47, 37, 30, 27, 24, 21, 19, 17, 16, 15, 14, 13, 12, 11, 11, 10, 10, 9, 9, 9],
    [57, 44, 36, 32, 29, 25, 22, 21, 19, 18, 16, 15, 15, 13, 13, 12, 12, 11, 10, 10],
    [68, 52, 42, 37, 34, 29, 26, 24, 22, 20, 19, 18, 17, 16, 15, 14, 13, 13, 12, 12],
    [81, 62, 50, 44, 40, 34, 30, 28, 26, 24, 22, 21, 20, 18, 17, 16, 16, 15, 14, 13],
    [93, 70, 56, 50, 45, 39, 34, 32, 29, 27, 24, 23, 22, 20, 19, 18, 18, 17, 16, 15],
    [106, 79, 63, 56, 50, 43, 38, 35, 33, 30, 27, 26, 24, 23, 21, 20, 19, 18, 17, 17],
    [124, 91, 72, 63, 56, 49, 43, 40, 37, 33, 30, 29, 27, 25, 24, 23, 22, 20, 19, 19],
    [139, 101, 79, 70, 62, 53, 47, 43, 40, 36, 33, 31, 30, 28, 26, 25, 24, 22, 21, 20],
    [160, 114, 89, 78, 69, 59, 52, 48, 44, 40, 37, 35, 33, 30, 28, 27, 26, 24, 23, 22],
    [180, 126, 97, 85, 75, 64, 56, 52, 48, 43, 39, 37, 35, 33, 30, 29, 28, 26, 25, 24],
    [196, 135, 104, 90, 80, 68, 59, 55, 51, 46, 42, 39, 37, 34, 32, 31, 29, 28, 26, 25]]


  def self.MN90_lookup(depth, bottom_time, options={})
    Rails.logger.debug "Calculating stops for bottom_time #{bottom_time}min at #{depth}m (#{options})"
    raise DBArgumentError.new "Depth out of bounds for MN90 tables" if depth > 65

    majoration = MN90_lookup_majoration(options[:gps], options[:surface], depth)
    Rails.logger.debug "Majoration is : #{majoration}"

    MN90.each do |line|
      next if line[0] < depth
      next if line[1] < bottom_time + majoration

      Rails.logger.debug "Using MN90 line : #{line.to_s}"

      ascent_duration = line[7] - line[2..6].map(&:to_i).sum
      dive_duration = bottom_time + line[7] + 3

      stops = []
      stops.push [15, line[2]] if line[2]
      stops.push [12, line[3]] if line[3]
      stops.push [9,  line[4]] if line[4]
      stops.push [6,  line[5]] if line[5]
      stops.push [3,  line[6].to_i + 3]

      result = {
        :bottom_time => bottom_time,
        :ascent_duration => ascent_duration,
        :dive_duration => dive_duration,
        :lost_time_3m => 0,
        :used_majoration => majoration,
        :stops => stops,
        :gps => majoration>0?nil:line[8]
      }
      Rails.logger.debug "Profile calculated based on MN90 for dive : #{result}"
      return result

    end

  end



  # Calculates the estimated profile of a dive that lasted #duration minutes (incl. ascent and stops)
  # Based on MN90 and adding 3min safety stops at 3m
  def self.MN90_reverse_lookup(depth, duration, options={})
    Rails.logger.debug "Calculating stops for dive #{duration}min at #{depth}m (#{options})"
    raise DBArgumentError.new "Depth out of bounds for MN90 tables" if depth > 65

    # if it is a successive dive, then calculates the time majoration
    majoration = MN90_lookup_majoration(options[:gps], options[:surface], depth)
    Rails.logger.debug "Majoration is : #{majoration}"

    possible_results = []

    # Look for the correct line of the table to use
    MN90.each do |line|
      next if line[0] < depth
      next if line[9] < duration + majoration
      next if line[7] > duration - 3

      Rails.logger.debug "Calculating for MN90 line : #{line.to_s}"

      ascent_duration = line[7] - line[2..6].map(&:to_i).sum
      expected_bottom_time = duration - ascent_duration - line[2..6].map(&:to_i).sum - 3
      bottom_time = [line[1], expected_bottom_time+majoration].min - majoration
      lost_time = expected_bottom_time - bottom_time

      next if bottom_time < 0

      stops = []
      stops.push [15, line[2]] if line[2]
      stops.push [12, line[3]] if line[3]
      stops.push [9,  line[4]] if line[4]
      stops.push [6,  line[5]] if line[5]
      stops.push [3,  line[6].to_i + 3 + lost_time]

      result = {
        :bottom_time => bottom_time,
        :ascent_duration => ascent_duration,
        :dive_duration => duration,
        :lost_time_3m => lost_time,
        :used_majoration => majoration,
        :stops => stops,
        :gps => majoration>0?nil:line[8]
      }
      Rails.logger.debug "Profile calculated based on MN90 for dive : #{result}"
      possible_results.push result
    end

    raise DBArgumentError.new "Duration out of bounds for MN90 tables" if possible_results.count == 0

    #returning the profile with the maximum bottom time
    possible_results.sort! do |r1, r2| r2[:bottom_time]-r1[:bottom_time] end
    Rails.logger.debug "Optimized profile based on MN90 : #{possible_results.first}"
    return possible_results.first
  end


  def self.MN90_lookup_majoration(gps, surface, depth)
    majoration = 0
    return 0 if surface.nil?
    return 0 if surface >= 12*60
    raise DBArgumentError.new "Consecutive dives not handled here" if surface < 15
    raise DBArgumentError.new "Successive dive out of bounds for MN90 tables" if gps.nil?

    col_idx_residuel = nil
    MN90_N2_RESIDUEL_SURFACE.each_with_index do |surf, idx|
      next if surf <= surface
      col_idx_residuel ||= [idx - 1, 0].max
    end
    n2_residuel = MN90_N2_RESIDUEL[gps][col_idx_residuel]

    Rails.logger.debug "n2_residuel : #{n2_residuel}"

    col_idx_major = nil
    MN90_SUCC_MAJOR_DEPTH.each_with_index do |d, idx|
      next if d <= depth
      col_idx_major ||= [idx - 1, 0].max
    end
    Rails.logger.debug col_idx_major

    row_idx_major = nil
    MN90_SUCC_MAJOR_N2.each_with_index do |n2, idx|
      next if n2 < n2_residuel
      row_idx_major ||= idx
    end
    Rails.logger.debug "Reading majoration on (#{row_idx_major}, #{col_idx_major})"

    return MN90_SUCC_MAJOR[row_idx_major][col_idx_major]
  end







  module Buhlmann16

    N2_STD_PRESSURE = 0.79
    SURFACE_PRESSURE = 1

    #half life N2, a N2, b N2, hl He, a He, b He
    COMPARTMENTS_ZHL16_B = [
      [5,    1.1696, 0.5578, 1.88,   1.6189,  0.4770],
      [8,    1,      0.6514, 3.02,   1.3830,  0.5747],
      [12.5, 0.8618, 0.7222, 4.72,   1.1919,  0.6527],
      [18.5, 0.7562, 0.7725, 6.99,   1.0458,  0.7223],
      [27,   0.6667, 0.8125, 10.21,  0.9220,  0.7582],
      [38.3, 0.5933, 0.8434, 14.48,  0.8205,  0.7957],
      [54.3, 0.5282, 0.8693, 20.53,  0.7305,  0.8279],
      [77,   0.4701, 0.891 , 29.11,  0.6502,  0.8553],
      [109,  0.4187, 0.9092, 41.20,  0.5950,  0.8757],
      [146,  0.3798, 0.9222, 55.19,  0.5545,  0.8903],
      [187,  0.3497, 0.9319, 70.69,  0.5333,  0.8997],
      [239,  0.3223, 0.9403, 90.34,  0.5189,  0.9073],
      [305,  0.2971, 0.9477, 115.29, 0.5181,  0.9122],
      [390,  0.2737, 0.9544, 147.42, 0.5176,  0.9171],
      [498,  0.2523, 0.9602, 188.24, 0.5172,  0.9217],
      [635,  0.2327, 0.9653, 240.03, 0.5119,  0.9267]]

    CEILING_STEPS = 3

    class Mix
      attr_reader :pct_o2
      attr_reader :pct_he

      def initialize o2, he=0
        @pct_o2 = o2
        @pct_he = he
      end

      def pct_n2
        1-pct_o2-pct_he
      end

      def get_pct gas
        send "pct_#{gas}"
      end
    end

    AIR = Mix.new(0.209, 0)

    class Compartment
      attr_reader :he_half_life
      attr_reader :he_a
      attr_reader :he_b
      attr_reader :he_tension
      attr_reader :he_history

      attr_reader :n2_half_life
      attr_reader :n2_a
      attr_reader :n2_b
      attr_reader :n2_tension
      attr_reader :n2_history

      def initialize n2_h, n2_a, n2_b, n2_t, he_h, he_a, he_b, he_t
        @n2_half_life = n2_h
        @n2_a = n2_a
        @n2_b = n2_b
        @n2_tension = n2_t
        @n2_history = [@n2_tension]

        @he_half_life = he_h
        @he_a = he_a
        @he_b = he_b
        @he_tension = he_t
        @he_history = [@he_tension]
      end

      def push depth, duration, mix=AIR
        n2_partial_pressure = mix.pct_n2 * (SURFACE_PRESSURE+depth.to_f/10.0)
        he_partial_pressure = mix.pct_he * (SURFACE_PRESSURE+depth.to_f/10.0)
        @n2_tension += (n2_partial_pressure - n2_tension) * ( 1 - 2**(-duration.to_f/n2_half_life) )
        @he_tension += (he_partial_pressure - he_tension) * ( 1 - 2**(-duration.to_f/he_half_life) )
        @n2_history.push @n2_tension
        @he_history.push @he_tension
      end

      def total_tension
        @n2_tension + @he_tension
      end

      def max_tolerated_ambient_pressure
        a = (@n2_a * @n2_tension + @he_a * @he_tension) / total_tension
        b = (@n2_b * @n2_tension + @he_b * @he_tension) / total_tension
        (total_tension - a)*b
      end

      def get_max_ambient_pressure gradient_factor=1
        total_tension + (max_tolerated_ambient_pressure - total_tension) * gradient_factor
      end
    end


    class CompartmentState
      attr_reader :compartments

      def initialize mix = AIR
        @compartments = []
        COMPARTMENTS_ZHL16_B.each do |cdata|
          @compartments.push Compartment.new(cdata[0], cdata[1], cdata[2], mix.pct_n2 * SURFACE_PRESSURE, cdata[3], cdata[4], cdata[5], mix.pct_he * SURFACE_PRESSURE)
        end
      end

      def push depth, duration, mix = AIR
        @compartments.each do |c|
          c.push depth, duration, mix
        end
        return self
      end

      def get_max_ambient_pressure gradient_factor=1
        ps = @compartments.map do |c|
          c.get_max_ambient_pressure gradient_factor
        end
        ps.max
      end

      def get_max_depth gradient_factor=1
        m = (get_max_ambient_pressure(gradient_factor) - SURFACE_PRESSURE) * 10
        m<0 ? 0 : m
      end

      def get_gf_for depth
        ambient_pressure = SURFACE_PRESSURE + depth.to_f/10
        gfs = @compartments.map do |c|
          (c.total_tension - ambient_pressure) / (c.total_tension - c.get_max_ambient_pressure)
        end
        gfs.max
      end

    end



    class DiveProfileIterator
      attr_reader :dive_id
      attr_reader :compartment_state
      attr_reader :current_time

      def initialize dive_id
        @dive_id = dive_id
        reset
      end

      def dive
        return @dive if @dive
        @dive = Dive.find(dive_id)
      end

      def profile_data
        return @profile_data unless @profile_data.nil?
        @profile_data = dive.raw_profile
      end

      def next
        next_step = profile_data.shift
        return nil if next_step.nil?
        compartment_state.push next_step.depth, ((next_step.seconds.to_f - @current_time)/60), current_mix
        @current_depth = next_step.depth
        @current_time = next_step.seconds
        return self
      end

      def reset
        @compartment_state = CompartmentState.new
        @current_time = 0.0
        @current_depth = 0.0
        @profile_data = nil
      end

      def gradient_factors
        gfs = []
        while self.next do
          gfs.push compartment_state.get_gf_for @current_depth
        end
        return gfs
      end

      def get_max_gf
        gradient_factors.max
      end

      def get_current_gf
        compartment_state.get_gf_for @current_depth
      end

      def current_mix
        begin
          tanks = dive.tanks.sort do |a, b| a.time_start <=> b.time_start end
          tanks.reject! do |t| t.time_start > @current_time end
          Mix.new tanks.last.pct_o2, tanks.last.pct_he
        rescue
          AIR
        end
      end

    end


  end



  module Engagement

    class GasLoadDepth
      SPACES = 100
      COEFF_ECHANGE = 0.003
      COEFF_DIFFUS = 0.00015
      DX = 0.1

      attr_reader :profile

      def initialize
        @profile = [0]*SPACES
      end

      def apply_pressure p, dt
        new_profile = @profile.dup
        @profile.each_with_index do |pi, idx|

          #    dP / dt = COEFF_DIFFUS  *  d2P / dx2

          if idx == 0 then
            new_profile[idx] += dt * ((p-pi) * COEFF_ECHANGE + COEFF_DIFFUS * (@profile[1]-pi) / DX) / DX
          elsif idx == SPACES - 1 then
            new_profile[idx] += dt * COEFF_DIFFUS * (@profile[idx-1]-pi) / (DX*DX)
          else
            new_profile[idx] += dt * COEFF_DIFFUS * (@profile[idx+1]+@profile[idx-1]-2*pi) / (DX*DX)
          end

        end
        @profile = new_profile
      end

      def engagement
        @profile.sum * DX / 0.107
      end

    end

    def self.for_dive dive_id
      gas_load = GasLoadDepth.new
      last_time = 0
      max_engagement = nil
      max_step_duration = 30
      max_applied_pressure = 0
      has_diverged = false

      ProfileData.where(dive_id: dive_id).order('seconds ASC').each do |position|
        next if last_time >= position.seconds
        next if position.depth.nil?
        pushed_duration = 0
        total_duration = position.seconds-last_time
        max_applied_pressure = position.depth / 10 if max_applied_pressure < position.depth / 10
        while pushed_duration < total_duration do
            step_duration = [max_step_duration, total_duration-pushed_duration].min
            gas_load.apply_pressure (position.depth/10), step_duration
            last_time = position.seconds
            max_engagement = gas_load.engagement if max_engagement.nil? || gas_load.engagement > max_engagement
            pushed_duration += step_duration
            gas_load.profile.each do |v|
              has_diverged ||= v > max_applied_pressure * 2
            end
        end
      end

      Rails.logger.warn "Calculation of engagement has diverged for dive #{dive_id}"

      return nil if has_diverged
      return max_engagement
    end


  end

end

