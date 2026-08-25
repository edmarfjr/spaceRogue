/// Prioridade de desenho topdown: quanto mais pra baixo (Y maior) o "chão" de
/// um componente, mais tarde ele desenha — por cima de quem tem Y menor.
/// Todo componente que compartilha a mesma camada visual (atores, obstáculos
/// parados) precisa usar essa mesma referência (a base do sprite, não o
/// centro), senão a ordem relativa entre eles vira sorte de inserção.
int ySortPriority(double feetY) => feetY.round();
