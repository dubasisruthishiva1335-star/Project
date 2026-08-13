import { Body, Controller, Delete, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../common/storage.service';
import { ConfirmContentDto } from './dto/confirm-content.dto';

@ApiTags('admin-notes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/notes')
export class NotesAdminController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  @Post('confirm')
  async confirm(@Body() dto: ConfirmContentDto) {
    let subjectId = dto.subjectId;
    const sem = dto.semester ?? dto.year ?? 1;

    if (!subjectId) {
      const existing = await this.prisma.subject.findFirst({
        where: { code: dto.subjectCode || 'GEN', branch: dto.branch, semester: sem },
      });
      const subject =
        existing ||
        (await this.prisma.subject.create({
          data: {
            name: dto.subjectName || dto.title,
            code: dto.subjectCode || 'GEN',
            branch: dto.branch,
            semester: sem,
          },
        }));
      subjectId = subject.id;
    }

    return this.prisma.academicContent.create({
      data: {
        subjectId,
        title: dto.title,
        contentType: dto.contentType as any,
        unit: dto.unit ?? 1,
        s3Key: dto.s3Key,
        fileUrl: dto.publicUrl || this.storage.publicUrlFor(dto.s3Key),
      },
    });
  }

  @Patch(':id')
  async updateContent(@Param('id') id: string, @Body() body: any) {
    return this.prisma.academicContent.update({
      where: { id },
      data: {
        ...(body.title ? { title: body.title } : {}),
        ...(body.unit ? { unit: Number(body.unit) } : {}),
        ...(body.contentType ? { contentType: body.contentType } : {}),
      },
    });
  }

  @Delete(':id')
  async deleteContent(@Param('id') id: string) {
    return this.prisma.academicContent.delete({
      where: { id },
    });
  }
}
