import { Injectable, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

function toLastnameFirstname(fullName: string): string {
  const parts = fullName.trim().split(/\s+/);
  if (parts.length < 2) return fullName.trim();
  const [first, ...rest] = parts;
  return `${rest.join(' ')} ${first}`;
}

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { hallTicket: dto.hallTicket } });
    if (existing) throw new ConflictException('An account with this hall ticket already exists.');

    const password = dto.password || dto.hallTicket;
    const passwordHash = await bcrypt.hash(password, 10);
    const sem = dto.semester ?? dto.year ?? 1;

    const user = await this.prisma.user.create({
      data: {
        hallTicket: dto.hallTicket,
        fullName: toLastnameFirstname(dto.fullName),
        email: dto.email,
        courseType: dto.courseType,
        branch: dto.branch,
        semester: sem,
        passwordHash,
      },
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { hallTicket: dto.hallTicket } });
    if (!user) throw new UnauthorizedException('Invalid hall ticket or password.');

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid hall ticket or password.');

    return this.buildAuthResponse(user);
  }

  private buildAuthResponse(user: {
    id: string;
    hallTicket: string;
    fullName: string;
    role: string;
    branch: string;
    semester: number;
  }) {
    const token = this.jwt.sign({ sub: user.id, hallTicket: user.hallTicket, role: user.role });
    return {
      accessToken: token,
      user: {
        id: user.id,
        hallTicket: user.hallTicket,
        fullName: user.fullName,
        role: user.role,
        branch: user.branch,
        semester: user.semester,
      },
    };
  }
}
